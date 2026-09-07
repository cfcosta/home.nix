"""Export local RomM Switch and PS3 games for Moonshine's desktop scanner."""

import argparse
import fcntl
import hashlib
import json
import os
import re
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path

PLATFORM_NAMES = {"switch": "Switch", "ps3": "PS3"}


class NoRedirect(urllib.request.HTTPRedirectHandler):
    # Never forward the RomM bearer token through an asset redirect.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Romm:
    def __init__(self, url, token):
        self.base = url.rstrip("/") + "/"
        self.token = token
        self.opener = urllib.request.build_opener(NoRedirect())
        if urllib.parse.urlsplit(self.base).scheme not in {"http", "https"}:
            raise ValueError("ROMM_URL must use HTTP or HTTPS")

    def get(self, path):
        url = urllib.parse.urljoin(self.base, path)
        parsed = urllib.parse.urlsplit(url)
        origin = urllib.parse.urlsplit(self.base)
        if (parsed.scheme, parsed.netloc) != (origin.scheme, origin.netloc):
            raise ValueError("Refusing a cover outside the configured RomM server")
        url = urllib.parse.quote(url, safe=":/?=&%")
        request = urllib.request.Request(
            url, headers={"Authorization": f"Bearer {self.token}"}
        )
        try:
            with self.opener.open(request, timeout=10) as response:
                data = response.read(32 * 1024 * 1024 + 1)
        except urllib.error.HTTPError as error:
            raise ValueError(f"RomM returned HTTP {error.code}") from None
        if len(data) > 32 * 1024 * 1024:
            raise ValueError("RomM response exceeds 32 MiB")
        return data

    def roms(self, slug):
        platforms = json.loads(self.get("api/platforms"))
        platform = next((p for p in platforms if p["fs_slug"] == slug), None)
        if platform is None:
            raise ValueError(
                f"RomM has no {slug} platform; retaining the previous export"
            )
        items = []
        seen = set()
        total = None
        while total is None or len(items) < total:
            query = urllib.parse.urlencode(
                {"platform_ids": platform["id"], "limit": 100, "offset": len(items)}
            )
            page = json.loads(self.get(f"api/roms?{query}"))
            if total is not None and total != page["total"]:
                raise ValueError("RomM library changed during pagination; retry later")
            total = page["total"]
            batch = page["items"]
            if not batch and len(items) != total:
                raise ValueError("Incomplete RomM page; retaining the previous export")
            for rom in batch:
                if rom["id"] in seen:
                    raise ValueError(
                        "Repeated RomM item; retaining the previous export"
                    )
                seen.add(rom["id"])
            items.extend(batch)
            if len(items) > total:
                raise ValueError("Inconsistent RomM total")
        return items


def local_game(rom, root):
    """Require one base title, never guess between dumps or launch DLC/updates."""
    name = Path(rom["fs_name"])
    if name.is_absolute() or ".." in name.parts or not name.parts:
        return None
    platform = rom.get("platform_fs_slug", "switch")
    if platform not in PLATFORM_NAMES:
        return None
    library = (root / platform).resolve()
    location = (library / name).resolve()
    if not location.is_relative_to(library):
        return None
    if platform == "ps3":
        return local_ps3_game(location, library)
    candidates = []
    for path in location.rglob("*") if location.is_dir() else [location]:
        if path.suffix.lower() not in {".xci", ".nsp"} or not path.is_file():
            continue
        # This library tags dumps with their Switch title ID: base IDs end in
        # 000, update IDs in 800, DLC IDs are different again. Fail closed for
        # untagged files instead of accidentally treating an update as a game.
        ids = re.findall(r"\[([0-9a-fA-F]{16})\]", path.name)
        if len(ids) != 1 or not ids[0].startswith("010") or not ids[0].endswith("000"):
            continue
        resolved = path.resolve()
        if resolved.is_relative_to(library):
            candidates.append(resolved)
    return candidates[0] if len(candidates) == 1 else None


def local_ps3_game(location, library):
    candidates = []
    for path in location.rglob("*") if location.is_dir() else [location]:
        if not path.is_file() or not path.resolve().is_relative_to(library):
            continue
        if path.suffix.lower() == ".iso":
            candidates.append(path.resolve())
        elif path.parts[-3:] == ("PS3_GAME", "USRDIR", "EBOOT.BIN"):
            disc = path.parents[2].resolve()
            metadata = disc / "PS3_GAME/PARAM.SFO"
            if metadata.is_file() and metadata.resolve().is_relative_to(library):
                # Boot the disc root so RPCS3 retains its disc/update context.
                candidates.append(disc)
    # PKG files are installers, including patches and DLC, not boot targets.
    return candidates[0] if len(candidates) == 1 else None


def desktop_value(value):
    return (
        value.replace("\\", "\\\\")
        .replace("\n", r"\n")
        .replace("\r", r"\r")
        .replace("\t", r"\t")
    )


def desktop_entry(title, game, cover, platform="switch"):
    command = {
        "switch": ["/run/current-system/sw/bin/eden", "-f", "-g"],
        "ps3": ["/run/current-system/sw/bin/rpcs3", "--no-gui", "--fullscreen"],
    }[platform]
    args = [
        "/run/current-system/sw/bin/env",
        "SDL_AUDIODRIVER=pulseaudio",
        "SDL_AUDIO_DRIVER=pulseaudio",
        *command,
        str(game),
    ]
    # Exec has two escaping layers: desktop strings, then quoted argv and
    # field-code expansion. Moonshine uses shlex without invoking a shell.
    quoted = []
    for arg in args:
        arg = arg.replace("%", "%%")
        arg = re.sub(r'([\\"`$])', r"\\\1", arg)
        quoted.append(f'"{arg}"')
    return (
        "[Desktop Entry]\nType=Application\nTerminal=false\n"
        f"Name={desktop_value(title)}\n"
        f"Exec={desktop_value(' '.join(quoted))}\n"
        f"Icon={desktop_value(str(cover))}\n"
    )


def cover_file(api, rom, output):
    path = rom.get("path_cover_large") or rom.get("path_cover_small")
    if not path:
        raise ValueError(f"RomM game {rom['id']} has no cover")
    # RomM includes its cover timestamp in this path, so changed art gets a
    # new immutable cache entry. Old paths stay valid for a running Moonshine.
    key = hashlib.sha256((getattr(api, "base", "") + path).encode()).hexdigest()
    cache = output / "covers"
    cache.mkdir(exist_ok=True)
    for suffix in ("jpg", "png", "webp"):
        existing = cache / f"{key}.{suffix}"
        if existing.exists():
            return existing
    data = api.get(path)
    if data.startswith(b"\xff\xd8\xff"):
        suffix = "jpg"
    elif data.startswith(b"\x89PNG\r\n\x1a\n"):
        suffix = "png"
    elif data.startswith(b"RIFF") and data[8:12] == b"WEBP":
        suffix = "webp"
    else:
        raise ValueError(f"RomM game {rom['id']} returned an unsupported cover")
    destination = cache / f"{key}.{suffix}"
    with tempfile.NamedTemporaryFile(dir=cache, delete=False) as temporary:
        temporary.write(data)
    Path(temporary.name).replace(destination)
    return destination


def refresh(api, root, output):
    # A missing library mount must not turn the last good listing into an empty
    # one. Individual deleted games, however, disappear on a successful refresh.
    for platform, label in PLATFORM_NAMES.items():
        if not (root / platform).is_dir():
            raise OSError(f"Local {label} library is unavailable")
    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    games = []
    for platform in PLATFORM_NAMES:
        for rom in api.roms(platform):
            if rom.get("platform_fs_slug", platform) != platform:
                raise ValueError("RomM returned a game from the wrong platform")
            rom = {**rom, "platform_fs_slug": platform}
            game = local_game(rom, root)
            if game is None:
                print(
                    f"Skipping RomM game {rom['id']}: no unambiguous local base dump",
                    file=sys.stderr,
                )
                continue
            games.append((platform, rom, game))
    names = Counter((platform, rom["name"]) for platform, rom, _ in games)
    entries = {}
    for platform, rom, game in games:
        ident = int(rom["id"])
        label = PLATFORM_NAMES[platform]
        title = f"{rom['name']} ({label})"
        if names[platform, rom["name"]] > 1:
            title = f"{rom['name']} ({label}, RomM {ident})"
        entries[f"{ident}.desktop"] = desktop_entry(
            title, game, cover_file(api, rom, output), platform
        )
    digest = hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()
    generations = output / "generations"
    generations.mkdir(exist_ok=True)
    generation = generations / digest
    if not generation.exists():
        with tempfile.TemporaryDirectory(dir=output) as staging:
            staged = Path(staging) / "entries"
            staged.mkdir()
            for name, content in entries.items():
                (staged / name).write_text(content, encoding="utf-8")
            staged.rename(generation)
    # The scanner sees a complete generation. No restart, signal or RomM write.
    with tempfile.TemporaryDirectory(dir=output) as staging:
        link = Path(staging) / "current"
        link.symlink_to(generation)
        link.replace(output / "current")
    # Keep immutable generations and covers: a concurrent scanner may still
    # be traversing the previous directory. Identical refreshes reuse both.
    return len(entries)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--roms-directory", required=True, type=Path)
    parser.add_argument("--output-directory", required=True, type=Path)
    args = parser.parse_args()
    try:
        args.output_directory.mkdir(parents=True, exist_ok=True)
        with (args.output_directory / ".lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                print("A RomM export is already running")
                return 0
            api = Romm(os.environ["ROMM_URL"], os.environ["ROMM_TOKEN"])
            count = refresh(api, args.roms_directory, args.output_directory)
            print(f"Exported {count} games; Moonshine reads them on its next start")
        return 0
    except (OSError, ValueError, KeyError) as error:
        print(f"RomM export failed; keeping previous listing: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
