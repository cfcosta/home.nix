"""Two-way sync of emulator saves with RomM.

RomM only ever learns that a save exists through its API: `scan_save()` is
called from the upload endpoint alone, and no library scan looks at asset files
on disk. Its own device-sync modes don't close the gap either -- the folder
watcher skips anything that isn't a file, and the SSH puller lists a single
level of regular files.

Two save shapes are handled, because the emulators disagree:

  * Eden (Switch), RPCS3 (PS3), Citra (3DS, under RetroArch) and Dolphin's Wii
    half keep a DIRECTORY per save, which RomM has no concept of. Those are
    shipped as a zip. RomM hashes zip uploads member-wise rather than over the
    container bytes (`_compute_zip_hash` in
    handler/filesystem/assets_handler.py), which is what makes this work: the
    server-side content_hash is reproducible here, so both sides compare for
    equality without downloading anything, and a rebuilt-but-identical archive
    doesn't look like a change just because its container bytes shifted.
  * RetroArch and Dolphin's GameCube half write a single flat file per game.
    Those go up verbatim -- no zip -- so the save stays readable by anything
    else that speaks the format, RomM's own web player included. RomM hashes
    those as a plain md5 (`_compute_file_hash`), which is reproduced here for
    the same reason.

Safety rules this follows, in order of importance:

  * Never touch a save while its emulator is running. A restore landing under a
    live emulator is how cloud sync eats a save file.
  * Never overwrite local state without first writing a copy of it to the
    backup directory. Every destructive step is recoverable from there.
  * On a genuine conflict (both sides changed since the last sync), the newer
    mtime wins, but the loser is still in backups.
"""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
import re
import shutil
import struct
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath

HOME = Path.home()
CONFIG_DIR = Path(
    os.environ.get("ROMM_SAVE_SYNC_CONFIG", HOME / ".config/romm-save-sync")
)
STATE_DIR = Path(
    os.environ.get("ROMM_SAVE_SYNC_STATE", HOME / ".local/state/romm-save-sync")
)

# Zip members get a fixed timestamp so a rebuild of unchanged content produces
# identical bytes. RomM's hash ignores timestamps, but determinism keeps the
# local backups from churning.
ZIP_EPOCH = (1980, 1, 1, 0, 0, 0)

# RomM inserts " [YYYY-MM-DD_HH-MM-SS]" before the extension when a save is
# uploaded with a slot, which is how history mode keeps revisions apart.
DATETIME_TAG = re.compile(r" \[\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\]")
TITLE_ID = re.compile(r"^[0-9A-Fa-f]{16}$")

failures = 0
verbose = False


def log(msg: str) -> None:
    print(msg, flush=True)


def debug(msg: str) -> None:
    """For conditions that are a normal steady state.

    Anything that would otherwise repeat unchanged on every timer tick belongs
    here, not in log(): an unmatched save is not news the twentieth time.
    """
    if verbose:
        print(msg, flush=True)


def warn(msg: str) -> None:
    print(f"warning: {msg}", file=sys.stderr, flush=True)


def fail(msg: str) -> None:
    global failures
    failures += 1
    print(f"error: {msg}", file=sys.stderr, flush=True)


class RommError(RuntimeError):
    pass


# --------------------------------------------------------------------------
# RomM API client
# --------------------------------------------------------------------------


class Romm:
    """The slice of RomM's API this needs, over stdlib urllib."""

    def __init__(self, base_url: str, token: str, timeout: int = 120) -> None:
        self.base = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout

    def _request(
        self,
        method: str,
        path: str,
        params: dict | None = None,
        data: bytes | None = None,
        content_type: str | None = None,
    ) -> bytes:
        url = f"{self.base}/api{path}"
        if params:
            clean = {k: v for k, v in params.items() if v is not None}
            url = f"{url}?{urllib.parse.urlencode(clean)}"

        request = urllib.request.Request(url, data=data, method=method)
        request.add_header("Authorization", f"Bearer {self.token}")
        if content_type:
            request.add_header("Content-Type", content_type)

        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            detail = exc.read()[:400].decode("utf-8", "replace").strip()
            raise RommError(f"{method} {path} -> HTTP {exc.code}: {detail}") from exc
        except urllib.error.URLError as exc:
            raise RommError(f"{method} {path} -> {exc.reason}") from exc

    def _json(self, path: str, **params) -> object:
        return json.loads(self._request("GET", path, params=params))

    def platforms(self) -> list[dict]:
        return self._json("/platforms")  # type: ignore[return-value]

    def roms(self, platform_id: int) -> list[dict]:
        # The roms listing is paginated (LimitOffsetPage); even the largest
        # platform here fits in one page well under the endpoint's 10k cap.
        page = self._json("/roms", platform_ids=platform_id, limit=10000)
        return page["items"] if isinstance(page, dict) else page

    def search(self, term: str) -> list[dict]:
        page = self._json("/roms", search_term=term, limit=25)
        return page["items"] if isinstance(page, dict) else page

    def saves(self, platform_id: int) -> list[dict]:
        return self._json("/saves", platform_id=platform_id)  # type: ignore[return-value]

    def download(self, save_id: int) -> bytes:
        return self._request("GET", f"/saves/{save_id}/content")

    def upload(
        self,
        rom_id: int,
        emulator: str,
        filename: str,
        blob: bytes,
        history: int = 0,
    ) -> dict:
        if history > 0:
            # Slot mode: RomM datetime-tags the filename, so each upload is a
            # new revision. overwrite=false is what enables its content-hash
            # dedupe, and autocleanup caps how many revisions are kept.
            params = {
                "rom_id": rom_id,
                "emulator": emulator,
                "slot": "romm-save-sync",
                "overwrite": "false",
                "autocleanup": "true",
                "autocleanup_limit": history,
            }
        else:
            # No slot: the filename stays as sent and the existing row is
            # updated in place. Nothing is ever deleted server-side.
            params = {"rom_id": rom_id, "emulator": emulator, "overwrite": "true"}

        boundary = "----romm-save-sync-boundary"
        body = b"".join(
            [
                f"--{boundary}\r\n".encode(),
                (
                    'Content-Disposition: form-data; name="saveFile"; '
                    f'filename="{filename}"\r\n'
                ).encode(),
                b"Content-Type: application/octet-stream\r\n\r\n",
                blob,
                f"\r\n--{boundary}--\r\n".encode(),
            ]
        )
        raw = self._request(
            "POST",
            "/saves",
            params=params,
            data=body,
            content_type=f"multipart/form-data; boundary={boundary}",
        )
        return json.loads(raw)


class Library:
    """Lazily-fetched view of RomM.

    RetroArch spans nine platforms and several thousand ROMs. Fetching all of
    that every five minutes to discover that nothing changed would be absurd,
    so rom listings are pulled only for a platform that actually has a save on
    one side or the other.
    """

    def __init__(self, romm: Romm) -> None:
        self.romm = romm
        self._platforms: dict[str, dict] | None = None
        self._roms: dict[str, list[dict]] = {}
        self._searches: dict[str, list[dict]] = {}

    @property
    def platforms(self) -> dict[str, dict]:
        if self._platforms is None:
            self._platforms = {p["fs_slug"]: p for p in self.romm.platforms()}
        return self._platforms

    def roms(self, slug: str) -> list[dict]:
        if slug not in self._roms:
            self._roms[slug] = self.romm.roms(self.platforms[slug]["id"])
        return self._roms[slug]

    def search(self, term: str) -> list[dict]:
        if term not in self._searches:
            self._searches[term] = self.romm.search(term)
        return self._searches[term]

    def saves(self, slug: str) -> list[dict]:
        return self.romm.saves(self.platforms[slug]["id"])


# --------------------------------------------------------------------------
# Packaging: a save is either a directory (zipped) or a single file (verbatim)
# --------------------------------------------------------------------------


def read_tree(root: Path) -> list[tuple[str, bytes]]:
    """Every regular file under `root`, as (posix-relative-name, bytes).

    Symlinks are skipped rather than followed: nothing in either emulator's
    save layout uses them, and following one would silently pull in a file from
    outside the save directory.
    """
    members = []
    for path in sorted(root.rglob("*")):
        if path.is_symlink() or not path.is_file():
            continue
        members.append((path.relative_to(root).as_posix(), path.read_bytes()))
    return sorted(members)


def zip_content_hash(members: list[tuple[str, bytes]]) -> str:
    """Reproduce RomM's hash for a zipped upload.

    Must stay byte-identical to `_compute_zip_hash`: md5 of "name:md5hex" lines
    joined by newlines, members in sorted name order.
    """
    lines = [
        f"{name}:{hashlib.md5(blob, usedforsecurity=False).hexdigest()}"
        for name, blob in members
    ]
    return hashlib.md5("\n".join(lines).encode(), usedforsecurity=False).hexdigest()


def file_content_hash(blob: bytes) -> str:
    """Reproduce RomM's hash for a non-zip upload (`_compute_file_hash`)."""
    return hashlib.md5(blob, usedforsecurity=False).hexdigest()


def build_zip(members: list[tuple[str, bytes]]) -> bytes:
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        for name, blob in members:
            info = zipfile.ZipInfo(name, date_time=ZIP_EPOCH)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            archive.writestr(info, blob)
    return buffer.getvalue()


def extract_zip(blob: bytes, destination: Path) -> None:
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        for name in archive.namelist():
            if name.endswith("/"):
                continue
            target = destination.joinpath(name).resolve()
            # Reject members that would escape the save directory.
            if not str(target).startswith(f"{destination.resolve()}{os.sep}"):
                raise RommError(f"zip member escapes the save directory: {name}")
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(name))


def replace_tree(blob: bytes, target: Path) -> None:
    """Swap `target` for the archive's contents.

    Extraction happens beside the target and only then takes its place, so an
    interrupted or corrupt download can't leave a half-written save behind.
    """
    staging = target.with_name(f"{target.name}.romm-new")
    previous = target.with_name(f"{target.name}.romm-old")
    shutil.rmtree(staging, ignore_errors=True)
    shutil.rmtree(previous, ignore_errors=True)

    staging.mkdir(parents=True)
    extract_zip(blob, staging)

    if target.exists():
        target.rename(previous)
    staging.rename(target)
    shutil.rmtree(previous, ignore_errors=True)


def replace_file(blob: bytes, target: Path) -> None:
    """Same idea for a single-file save: stage beside it, then rename over."""
    target.parent.mkdir(parents=True, exist_ok=True)
    staging = target.with_name(f".{target.name}.romm-new")
    staging.write_bytes(blob)
    staging.replace(target)


def backup(emulator: str, remote_name: str, blob: bytes) -> Path:
    """Snapshot the current local save before anything overwrites it."""
    stamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d_%H-%M-%S")
    name = PurePosixPath(remote_name.replace(os.sep, "_"))
    directory = STATE_DIR / "backups" / emulator
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{name.stem}-{stamp}{name.suffix}"
    path.write_bytes(blob)
    return path


def strip_datetime_tag(name: str) -> str:
    return DATETIME_TAG.sub("", name, count=1)


def normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


RETROARCH_CONFIG = HOME / ".config/retroarch/retroarch.cfg"
RETROARCH_SAVES_FALLBACK = HOME / ".config/retroarch/saves"
RETROARCH_PROCESSES = ("retroarch",)


def retroarch_saves_root() -> Path:
    """RetroArch's save directory, read back from its config rather than assumed.

    The wrapper pins savefile_directory declaratively, but following the file
    means a directory changed by hand doesn't silently strand the sync.
    """
    try:
        text = RETROARCH_CONFIG.read_text(errors="replace")
    except OSError:
        return RETROARCH_SAVES_FALLBACK
    match = re.search(r'^savefile_directory\s*=\s*"(.*)"\s*$', text, re.MULTILINE)
    if not match or match.group(1) in ("", "default"):
        return RETROARCH_SAVES_FALLBACK
    return Path(os.path.expanduser(match.group(1)))


# --------------------------------------------------------------------------
# Emulator adapters
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class LocalSave:
    platform_slug: str
    key: str
    path: Path
    # Set during discovery when the layout already identifies the game, which
    # saves guessing later.
    rom_id: int | None = None

    @property
    def mtime(self) -> datetime:
        newest = self.path.stat().st_mtime
        if self.path.is_dir():
            for path in self.path.rglob("*"):
                if path.is_file():
                    newest = max(newest, path.stat().st_mtime)
        return datetime.fromtimestamp(newest, tz=timezone.utc)


@dataclass(frozen=True)
class Packed:
    blob: bytes
    content_hash: str
    files: int
    size: int


def pack_tree(path: Path) -> Packed:
    members = read_tree(path)
    blob = build_zip(members) if members else b""
    size = sum(len(data) for _, data in members)
    return Packed(blob, zip_content_hash(members), len(members), size)


def pack_file(path: Path) -> Packed:
    blob = path.read_bytes()
    return Packed(blob, file_content_hash(blob), 1, len(blob))


class Adapter:
    name: str
    processes: tuple[str, ...]
    platform_slugs: tuple[str, ...]

    def discover(self, library: Library) -> list[LocalSave]:
        raise NotImplementedError

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        """Map a local save to a RomM rom id."""
        raise NotImplementedError

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        """Where a save that only exists server-side should be restored to."""
        raise NotImplementedError

    def pack(self, path: Path) -> Packed:
        raise NotImplementedError

    def unpack(self, blob: bytes, target: Path) -> None:
        raise NotImplementedError

    def remote_name(self, key: str) -> str:
        raise NotImplementedError

    def key_for(self, remote_name: str) -> str:
        raise NotImplementedError


class DirectoryAdapter(Adapter):
    """Saves are directories, so RomM gets one zip per save."""

    def pack(self, path: Path) -> Packed:
        return pack_tree(path)

    def unpack(self, blob: bytes, target: Path) -> None:
        replace_tree(blob, target)

    def remote_name(self, key: str) -> str:
        return f"{key}.zip"

    def key_for(self, remote_name: str) -> str:
        stem = strip_datetime_tag(remote_name)
        return stem[:-4] if stem.lower().endswith(".zip") else stem


class FileAdapter(Adapter):
    """Saves are single files, uploaded verbatim.

    Not zipped on purpose: a bare `.srm` stays loadable by every other thing
    that reads the format, including RomM's own web player, which a wrapper
    archive would break.
    """

    def pack(self, path: Path) -> Packed:
        return pack_file(path)

    def unpack(self, blob: bytes, target: Path) -> None:
        replace_file(blob, target)

    def remote_name(self, key: str) -> str:
        return key

    def key_for(self, remote_name: str) -> str:
        return strip_datetime_tag(remote_name)


class Eden(DirectoryAdapter):
    """Eden (Switch): nand/user/save/<space-id>/<user-uuid>/<title-id>/."""

    name = "eden"
    platform_slugs = ("switch",)
    processes = ("eden", "eden-cli")
    root = HOME / ".local/share/eden/nand/user/save"

    def discover(self, library: Library) -> list[LocalSave]:
        found: dict[str, LocalSave] = {}
        for path in sorted(self.root.glob("*/*/*")):
            if not path.is_dir() or not TITLE_ID.match(path.name):
                continue
            key = path.name.upper()
            save = LocalSave("switch", key, path)
            # One title under two user profiles is possible; the freshest one
            # is the save actually being played.
            if key in found and found[key].mtime >= save.mtime:
                warn(f"eden: {key} exists under several profiles, using the newest")
                continue
            found[key] = save
        return list(found.values())

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        # Switch ROM filenames carry the title id in brackets -- the same
        # identifier RomM matches against its TitleDB index, so it is the
        # authoritative link between a save directory and a rom.
        for rom in roms:
            if f"[{save.key}]" in (rom.get("fs_name") or "").upper():
                return rom["id"]
        return None

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        profiles = sorted(p for p in self.root.glob("*/*") if p.is_dir())
        if not profiles:
            return None
        return profiles[-1] / key


class Rpcs3(DirectoryAdapter):
    """RPCS3 (PS3): dev_hdd0/home/<user>/savedata/<PRODUCT>-<SLOT>/."""

    name = "rpcs3"
    platform_slugs = ("ps3",)
    processes = ("rpcs3",)
    root = HOME / ".config/rpcs3/dev_hdd0/home"

    def discover(self, library: Library) -> list[LocalSave]:
        saves = []
        for path in sorted(self.root.glob("*/savedata/*")):
            if path.is_dir() and not path.name.startswith("."):
                saves.append(LocalSave("ps3", path.name, path))
        return saves

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        # PS3 dumps are usually named for the product code, so try that first.
        product = save.key.split("-", 1)[0].upper()
        for rom in roms:
            if product in (rom.get("fs_name") or "").upper():
                return rom["id"]

        # RomM stores no serial for PS3, and a rom named after the game rather
        # than its code (the common case for a redump) can't be matched that
        # way. PARAM.SFO inside the save carries the game's own title, which
        # closes the gap without hand-maintained mappings.
        title = sfo_title(save.path / "PARAM.SFO")
        if not title:
            return None
        wanted = strip_save_suffix(normalize(title))
        if not wanted:
            return None

        prefixed: list[tuple[int, int]] = []
        for rom in roms:
            for name in (rom.get("name"), rom.get("fs_name_no_tags")):
                if not name:
                    continue
                candidate = normalize(name)
                if candidate == wanted:
                    return rom["id"]
                # A title the suffix list didn't fully clean still starts with
                # the game's name. Collect rather than return, and take the
                # longest match, so a short name can't outrank a specific one.
                if len(candidate) >= 4 and wanted.startswith(candidate):
                    prefixed.append((len(candidate), rom["id"]))

        return max(prefixed)[1] if prefixed else None

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        users = sorted(p for p in self.root.glob("*") if (p / "savedata").is_dir())
        if not users:
            return None
        return users[0] / "savedata" / key


class RetroArch(FileAdapter):
    """RetroArch: one flat save file per game, under a per-content folder.

    `sort_savefiles_by_content_enable` (set declaratively in the wrapper) puts
    each save in a folder named after the directory its content came from. For
    this library that folder is the RomM platform slug -- roms/gba/… ->
    saves/gba/… -- which is the only thing that ties a bare `.srm` back to a
    platform. Multi-track disc rips live in a directory of their own, so those
    sort under the game's folder name instead; both cases are resolved below.
    """

    name = "retroarch"
    processes = RETROARCH_PROCESSES
    # Every platform RomM holds ROMs for that RetroArch emulates here. Switch
    # and PS3 are absent because libretro has no core for either; GameCube and
    # Wii because the core that does exist writes one memory card image for the
    # whole library, with no way back from a save to a game. eden, rpcs3 and
    # dolphin cover all four.
    platform_slugs = (
        "3ds",
        "gb",
        "gba",
        "gbc",
        "nds",
        "psx",
        "segacd",
        "snes",
    )

    @property
    def root(self) -> Path:
        return retroarch_saves_root()

    def _owner(self, folder: str, library: Library) -> tuple[str | None, int | None]:
        if folder in self.platform_slugs:
            return folder, None
        # Not a platform, so this is a game that lives in a directory of its
        # own -- a multi-track disc rip -- and the folder is the rom's fs_name.
        # Search by name instead of scanning every platform's rom list: an
        # unmatched folder (one left behind by a core this no longer syncs,
        # say) is permanent, and paying thousands of rom records for it on
        # every tick is not.
        for rom in library.search(folder):
            if (rom.get("fs_name") or "") != folder:
                continue
            slug = rom.get("platform_fs_slug")
            if slug in self.platform_slugs:
                return slug, rom["id"]
        debug(f"retroarch: save folder {folder!r} matches no platform or ROM")
        return None, None

    def discover(self, library: Library) -> list[LocalSave]:
        root = self.root
        if not root.is_dir():
            return []

        saves = []
        for folder in sorted(root.iterdir()):
            if folder.name.startswith("."):
                continue
            if not folder.is_dir():
                # Sorting is on, so a file sitting at the top level predates it
                # (or came from another frontend) and has no platform to
                # attribute it to.
                debug(f"retroarch: {folder.name} is not in a per-content folder")
                continue
            slug, rom_id = self._owner(folder.name, library)
            if slug is None:
                continue
            for path in sorted(folder.iterdir()):
                if path.is_file() and not path.name.startswith("."):
                    saves.append(LocalSave(slug, path.name, path, rom_id))
        return saves

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        if save.rom_id is not None:
            return save.rom_id
        # The save is named after the content, so its stem is the ROM's stem --
        # true for a bare `.gba` and for a `.zip` whose inner file shares the
        # archive's name.
        stem = PurePosixPath(save.key).stem
        for rom in roms:
            if PurePosixPath(rom.get("fs_name") or "").stem == stem:
                return rom["id"]
        wanted = normalize(stem)
        for rom in roms:
            if normalize(PurePosixPath(rom.get("fs_name") or "").stem) == wanted:
                return rom["id"]
        return None

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        # The sort folder is named after the directory the content sits in:
        # the platform directory for a plain ROM file, the game's own
        # directory for a multi-track disc rip.
        folder = slug
        if rom and rom.get("has_multiple_files") and rom.get("fs_name"):
            folder = rom["fs_name"]
        return self.root / folder / key


class Citra(DirectoryAdapter):
    """Citra (3DS) running under RetroArch.

    Citra emulates the 3DS filesystem, so a save is a DIRECTORY sitting at
    sdmc/Nintendo 3DS/<id0>/<id1>/title/<high>/<low>/data/00000001 -- keyed by
    title id, with nothing anywhere in the path naming the game. The title id
    is in the ROM's own NCSD header, so unlike every other adapter here this
    one has to read the library to know what it is looking at.

    Only the title's savedata is carried. Some games keep extra state in
    extdata, which is keyed by a different id that doesn't map cleanly onto a
    rom, so it is left alone rather than guessed at.
    """

    name = "citra"
    platform_slugs = ("3ds",)
    # Citra is a libretro core, so the process to look for is its frontend.
    processes = RETROARCH_PROCESSES

    def __init__(self) -> None:
        self._titles: dict[str, int] | None = None

    @property
    def root(self) -> Path:
        # Citra appends "Citra/" to whatever save directory the frontend hands
        # it, and with per-content sorting on that directory is <saves>/3ds.
        return retroarch_saves_root() / "3ds" / "Citra" / "sdmc" / "Nintendo 3DS"

    def discover(self, library: Library) -> list[LocalSave]:
        root = self.root
        if not root.is_dir():
            return []

        saves = []
        for path in sorted(root.glob("*/*/title/*/*/data/00000001")):
            if not path.is_dir():
                continue
            low = path.parent.parent.name
            high = path.parent.parent.parent.name
            if not re.fullmatch(r"[0-9A-Fa-f]{8}", high) or not re.fullmatch(
                r"[0-9A-Fa-f]{8}", low
            ):
                continue
            saves.append(LocalSave("3ds", f"{high}{low}".upper(), path))
        return saves

    def _title_ids(self, roms: list[dict]) -> dict[str, int]:
        """Title id -> rom id, read out of the dumps in the ROM library."""
        if self._titles is not None:
            return self._titles

        self._titles = {}
        directory = os.environ.get("ROMM_SAVE_SYNC_ROMS")
        if not directory:
            debug("citra: ROMM_SAVE_SYNC_ROMS is unset, cannot identify title ids")
            return self._titles

        by_name = {rom.get("fs_name"): rom["id"] for rom in roms}
        for path in sorted((Path(directory) / "3ds").glob("*")):
            rom_id = by_name.get(path.name)
            if rom_id is None or not path.is_file():
                continue
            title = ncsd_title_id(path)
            if title:
                self._titles[title] = rom_id
        return self._titles

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        return self._title_ids(roms).get(save.key)

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        # id0/id1 come from the emulated SD card and are only created once a
        # game has actually run. Inventing them would put the save somewhere
        # Citra never looks, so a restore waits for the profile to exist.
        profiles = sorted(p for p in self.root.glob("*/*") if p.is_dir())
        if not profiles:
            return None
        return (
            profiles[-1]
            / "title"
            / key[:8].lower()
            / key[8:].lower()
            / "data"
            / "00000001"
        )


def read_head(path: Path, size: int) -> bytes | None:
    """The first `size` bytes of a dump, straight or inside a zip.

    Identifying a dump never needs more than its header, so a 4 GiB cart costs
    the same as a small one -- and inside a zip, only as much as decompressing
    that prefix.
    """
    try:
        if path.suffix.lower() == ".zip":
            with zipfile.ZipFile(path) as archive:
                names = [n for n in archive.namelist() if not n.endswith("/")]
                if not names:
                    return None
                with archive.open(names[0]) as handle:
                    return handle.read(size)
        with open(path, "rb") as handle:
            return handle.read(size)
    except (OSError, zipfile.BadZipFile):
        return None


def ncsd_title_id(path: Path) -> str | None:
    """Title id from a 3DS dump.

    NCSD (a .cci/.3ds cart dump) carries "NCSD" at 0x100 and the media/title id
    as a little-endian u64 at 0x108.
    """
    head = read_head(path, 0x200)
    if head is None or len(head) < 0x110 or head[0x100:0x104] != b"NCSD":
        return None
    return f"{struct.unpack_from('<Q', head, 0x108)[0]:016X}"


class Dolphin(Adapter):
    """Dolphin (GameCube and Wii), whose two consoles save differently.

      * A GameCube save is a single .gci file in the folder Dolphin exposes to
        the console as memory card slot A: GC/<REGION>/Card A/. The alternative
        Dolphin offers -- a .raw memory card image -- is ONE file holding every
        game's saves at once, which no amount of work would tie back to a
        single rom. That shape is what the libretro Dolphin core writes, and
        why GameCube saves were never synced before; emulation.nix pins slot A
        to the folder so this one can't silently turn back into that one.
      * A Wii save is a DIRECTORY in the emulated NAND, at
        Wii/title/00010000/<game code in hex>/data. 00010000 is the range for
        disc-based games, which is all RomM's wii platform holds -- channels
        and WiiWare live under their own ranges and belong to no rom here.

    Neither path names the game, and RomM stores no serial to match against, so
    the link back to a rom is the disc's own game id, read out of the dumps in
    the ROM library exactly as Citra's title ids are.
    """

    name = "dolphin"
    platform_slugs = ("ngc", "wii")
    # Neither of these is what /proc/<pid>/comm reports, because nixpkgs ships
    # Dolphin wrapped -- see process_names(), which is what makes them match.
    processes = ("dolphin-emu", "dolphin-emu-nogui")
    root = HOME / ".local/share/dolphin-emu"

    def __init__(self) -> None:
        self._ids: dict[str, dict[str, int]] = {}

    def discover(self, library: Library) -> list[LocalSave]:
        saves = []
        # Slot A only: it is the one slot Dolphin fits a card into by default,
        # and a game writes to whichever card it was told about, not both.
        for path in sorted(self.root.glob("GC/*/Card A/*.gci")):
            if path.is_file():
                saves.append(LocalSave("ngc", path.name, path))
        for path in sorted(self.root.glob("Wii/title/00010000/*/data")):
            title = path.parent.name
            if path.is_dir() and re.fullmatch(r"[0-9A-Fa-f]{8}", title):
                saves.append(LocalSave("wii", title.upper(), path))
        return saves

    def resolve(self, save: LocalSave, roms: list[dict]) -> int | None:
        wanted = game_id_from_key(save.platform_slug, save.key)
        if wanted is None:
            debug(f"dolphin: {save.key!r} carries no game id")
            return None
        return self._game_ids(save.platform_slug, roms).get(wanted)

    def _game_ids(self, slug: str, roms: list[dict]) -> dict[str, int]:
        """Game id -> rom id, read out of the dumps in the ROM library.

        Keyed by the full six-character id for GameCube, whose .gci filenames
        carry both the game code and the maker code, and by the four-character
        game code alone for the Wii, whose NAND path carries only that.
        """
        if slug in self._ids:
            return self._ids[slug]

        index: dict[str, int] = {}
        self._ids[slug] = index

        directory = os.environ.get("ROMM_SAVE_SYNC_ROMS")
        if not directory:
            debug("dolphin: ROMM_SAVE_SYNC_ROMS is unset, cannot identify game ids")
            return index

        width = 4 if slug == "wii" else 6
        by_name = {rom.get("fs_name"): rom["id"] for rom in roms}
        for path in sorted((Path(directory) / slug).glob("*")):
            rom_id = by_name.get(path.name)
            if rom_id is None or not path.is_file():
                continue
            game_id = disc_game_id(path)
            if game_id:
                index[game_id[:width]] = rom_id
        return index

    def target_for(self, slug: str, key: str, rom: dict | None) -> Path | None:
        # Unlike Eden's profiles or Citra's emulated SD card, both of these
        # paths follow from the game alone, and Dolphin creates them itself
        # when it needs them. So a save that exists only on the server can be
        # restored before the game has ever been launched here.
        if slug == "wii":
            return self.root / "Wii/title/00010000" / key.lower() / "data"

        game_code = gci_game_code(key)
        if game_code is None:
            return None
        region = GC_REGIONS.get(game_code[3])
        if region is None:
            warn(f"dolphin: {game_code} has no region Dolphin keeps a card for")
            return None
        return self.root / "GC" / region / "Card A" / key

    def pack(self, path: Path) -> Packed:
        return pack_tree(path) if path.is_dir() else pack_file(path)

    def unpack(self, blob: bytes, target: Path) -> None:
        # What came back says which console it belongs to: a zip is a Wii save
        # directory, anything else the bytes of a GameCube .gci. Reading it off
        # the archive rather than off the key keeps this honest if RomM ever
        # hands back something the key didn't predict.
        if blob[:2] == b"PK":
            replace_tree(blob, target)
        else:
            replace_file(blob, target)

    def remote_name(self, key: str) -> str:
        return key if key.lower().endswith(".gci") else f"{key}.zip"

    def key_for(self, remote_name: str) -> str:
        stem = strip_datetime_tag(remote_name)
        return stem[:-4] if stem.lower().endswith(".zip") else stem


# Dolphin writes a .gci as "<maker code>-<game code>-<the name the game gave
# the save>.gci", and only the first two fields are fixed-width -- the third is
# whatever the game called it, dashes and all.
GCI_NAME = re.compile(r"^(?P<maker>..)-(?P<game>....)-.*\.gci$", re.IGNORECASE)

# The country is the fourth character of the game code, and decides which
# region's memory card folder Dolphin keeps a game's saves in. Dolphin's own
# mapping consults the disc's expected region to settle a handful of Korean and
# store-exclusive releases; that is skipped here, because this table only
# decides where a restore lands and both readings of those releases name a
# folder Dolphin will look in for some region of the same game.
GC_REGIONS = {
    "B": "USA",
    "E": "USA",
    "N": "USA",
    "J": "JAP",
    "K": "JAP",
    "Q": "JAP",
    "T": "JAP",
    "W": "JAP",
    "D": "EUR",
    "F": "EUR",
    "H": "EUR",
    "I": "EUR",
    "L": "EUR",
    "M": "EUR",
    "P": "EUR",
    "R": "EUR",
    "S": "EUR",
    "U": "EUR",
    "V": "EUR",
    "X": "EUR",
    "Y": "EUR",
    "Z": "EUR",
}


def gci_game_code(key: str) -> str | None:
    match = GCI_NAME.match(key)
    return match.group("game").upper() if match else None


def game_id_from_key(slug: str, key: str) -> str | None:
    """The game id a Dolphin save key identifies its game by.

    Six characters for GameCube, whose .gci filename holds the game code and
    the maker code; four for the Wii, whose title id is the game code spelled
    out in hex and carries no maker code to match on.
    """
    if slug == "wii":
        try:
            return bytes.fromhex(key).decode("ascii").upper()
        except (ValueError, UnicodeDecodeError):
            return None

    match = GCI_NAME.match(key)
    if not match:
        return None
    return (match.group("game") + match.group("maker")).upper()


# GameCube and Wii discs open with the same six-character game id, and are told
# apart by a magic word later in that header. Both are in its first 0x20 bytes.
GC_MAGIC = b"\xc2\x33\x9f\x3d"
WII_MAGIC = b"\x5d\x1c\x9e\xa3"

# Far enough into a dump to reach the disc header in every container below --
# which means past a CISO's 0x8000-byte block map, the deepest of them.
DISC_PREFIX = 0x8020


def disc_header(head: bytes) -> bytes:
    """Find the disc header in the front of whatever container it arrived in."""
    if head[:4] == b"CISO":
        # Compact ISO: a fixed 0x8000-byte header (magic, block size, then one
        # flag per block) and then the blocks that survived, so the disc itself
        # starts exactly where the map ends.
        return head[0x8000:0x8020]

    if head[:4] == b"WBFS" and len(head) > 8:
        # A WBFS partition copies the disc header to the start of its second
        # hardware sector, whose size the file header gives as a power of two.
        offset = 1 << head[8]
        return head[offset : offset + 0x20]

    if head[:3] in (b"WIA", b"RVZ") and head[3:4] == b"\x01":
        # RVZ and the WIA it grew out of both keep a copy of the disc's first
        # 0x80 bytes at a fixed spot in their second header, which follows the
        # 0x48-byte first one.
        return head[0x58:0x78]

    # Everything else is read as a plain image: .iso and .gcm, and the NKit
    # rewrites of both, which leave the original header at the front.
    return head[:0x20]


def disc_game_id(path: Path) -> str | None:
    """Game id from a GameCube or Wii dump."""
    head = read_head(path, DISC_PREFIX)
    if head is None or len(head) < 0x20:
        return None

    header = disc_header(head)
    if len(header) < 0x20:
        return None
    if header[0x1C:0x20] != GC_MAGIC and header[0x18:0x1C] != WII_MAGIC:
        return None

    game_id = header[:6].decode("ascii", "replace")
    return game_id.upper() if game_id.isalnum() else None


# PARAM.SFO's TITLE names the SAVE, not the game -- "Dragon's Crown Save Data"
# for a ROM RomM simply calls "Dragon's Crown". Longest suffix first, so
# "savedata" wins over the "data" that also matches it.
SAVE_SUFFIXES = ("savedata", "gamedata", "playdata", "savefile", "save", "data")


def strip_save_suffix(value: str) -> str:
    for suffix in SAVE_SUFFIXES:
        if value.endswith(suffix) and len(value) > len(suffix):
            return value[: -len(suffix)]
    return value


def sfo_title(path: Path) -> str | None:
    """Read the TITLE field out of a PS3 PARAM.SFO."""
    try:
        blob = path.read_bytes()
    except OSError:
        return None
    if len(blob) < 20 or blob[:4] != b"\x00PSF":
        return None

    key_table, data_table, entries = struct.unpack_from("<III", blob, 8)
    for index in range(entries):
        offset = 20 + index * 16
        if offset + 16 > len(blob):
            break
        key_offset, _fmt, length, _max, data_offset = struct.unpack_from(
            "<HHIII", blob, offset
        )
        start = key_table + key_offset
        end = blob.find(b"\x00", start)
        if end < 0 or blob[start:end] != b"TITLE":
            continue
        raw = blob[data_table + data_offset : data_table + data_offset + length]
        return raw.split(b"\x00")[0].decode("utf-8", "replace").strip()
    return None


ADAPTERS = {
    adapter.name: adapter
    for adapter in (Citra(), Dolphin(), Eden(), RetroArch(), Rpcs3())
}


# --------------------------------------------------------------------------
# Sync
# --------------------------------------------------------------------------


@dataclass
class Context:
    adapter: Adapter
    romm: Romm
    library: Library
    state: dict
    args: argparse.Namespace
    roms: list[dict] = field(default_factory=list)


# nixpkgs ships some programs -- Dolphin among them -- behind a launcher that
# execs ".<name>-wrapped" beside it, and /proc/<pid>/comm is that file's name
# cut to 15 characters, so a running Dolphin calls itself ".dolphin-emu-wr".
# Reading the executable back off the process and undoing the decoration is
# what lets an emulator be named here the way a person would name it.
WRAPPED = re.compile(r"^\.(.+)-wrapped$")


def process_names(entry: Path) -> set[str]:
    """Every name the process at /proc/<entry> answers to."""
    names = set()
    try:
        names.add((entry / "comm").read_text().strip())
    except OSError:
        pass  # exited between listing and reading

    try:
        executable = PurePosixPath(os.readlink(entry / "exe")).name
    except OSError:
        return names  # exited, or belongs to another user

    match = WRAPPED.match(executable)
    names.add(match.group(1) if match else executable)
    return names


def emulator_running(names: tuple[str, ...]) -> str | None:
    wanted = set(names)
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        found = wanted & process_names(entry)
        if found:
            return min(found)
    return None


def parse_time(value: str | None) -> datetime:
    if not value:
        return datetime.fromtimestamp(0, tz=timezone.utc)
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=timezone.utc)
    return parsed


def load_state() -> dict:
    path = STATE_DIR / "state.json"
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def write_state(state: dict) -> None:
    # Keys are emulator/platform/key, and none of the three segments can
    # contain a slash. Anything else is a leftover from the two-segment format
    # that predates multi-platform adapters: never read again, so drop it
    # rather than carry it forever.
    live = {k: v for k, v in state.items() if k.count("/") == 2}

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    path = STATE_DIR / "state.json"
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(live, indent=2, sort_keys=True))
    tmp.replace(path)


def remember(ctx: Context, ident: str, local_hash: str | None, server: str | None):
    ctx.state[ident] = {
        "local": local_hash,
        "server": server,
        "at": datetime.now(timezone.utc).isoformat(),
    }


def sync_adapter(adapter: Adapter, romm: Romm, library: Library, state, args) -> None:
    busy = emulator_running(adapter.processes)
    if busy and not args.force:
        log(f"{adapter.name}: {busy} is running -- skipping (--force overrides)")
        return

    active = [slug for slug in adapter.platform_slugs if slug in library.platforms]
    if not active:
        debug(f"{adapter.name}: none of its platforms exist in RomM")
        return

    ctx = Context(adapter=adapter, romm=romm, library=library, state=state, args=args)

    local_by_platform: dict[str, dict[str, LocalSave]] = {slug: {} for slug in active}
    for save in adapter.discover(library):
        if save.platform_slug in local_by_platform:
            local_by_platform[save.platform_slug][save.key] = save

    for slug in active:
        # Keep only the newest server-side revision per key. In history mode
        # there are several rows behind one save; in plain mode exactly one.
        remote: dict[str, dict] = {}
        for save in library.saves(slug):
            if save.get("emulator") != adapter.name:
                continue
            key = adapter.key_for(save["file_name"])
            current = remote.get(key)
            if current is None or parse_time(save["updated_at"]) > parse_time(
                current["updated_at"]
            ):
                remote[key] = save

        local = local_by_platform[slug]
        if not local and not remote:
            continue  # nothing here, so don't pay for this platform's rom list

        ctx.roms = library.roms(slug)
        for key in sorted(set(local) | set(remote)):
            try:
                sync_one(ctx, slug, key, local.get(key), remote.get(key))
            except (RommError, OSError) as exc:
                fail(f"{adapter.name}/{slug}/{key}: {exc}")


def sync_one(
    ctx: Context,
    slug: str,
    key: str,
    local: LocalSave | None,
    remote: dict | None,
) -> None:
    adapter = ctx.adapter
    ident = f"{adapter.name}/{slug}/{key}"
    previous = ctx.state.get(ident, {})

    packed = adapter.pack(local.path) if local else None
    if packed is not None and packed.files == 0:
        # An emulator creates the save directory on first launch and only fills
        # it on the first in-game save, so an empty one is a normal steady
        # state. Treat it as no local save at all rather than bailing out: a
        # save that exists only on the server has to be able to restore INTO
        # that directory, which an early return would block forever.
        local, packed = None, None

    if local is None and remote is None:
        debug(f"{ident}: empty locally and absent on the server")
        return

    if remote is None:
        rom_id = adapter.resolve(local, ctx.roms)  # type: ignore[arg-type]
        if rom_id is None:
            debug(f"{ident}: no matching ROM in RomM")
            return
        return push(ctx, ident, key, packed, rom_id)  # type: ignore[arg-type]

    if local is None:
        return pull(ctx, ident, slug, key, remote, None)

    assert packed is not None
    if packed.content_hash == remote.get("content_hash"):
        remember(ctx, ident, packed.content_hash, remote.get("content_hash"))
        debug(f"{ident}: in sync")
        return

    local_changed = previous.get("local") != packed.content_hash
    server_changed = previous.get("server") != remote.get("content_hash")

    if local_changed and not server_changed:
        return push(ctx, ident, key, packed, remote["rom_id"])
    if server_changed and not local_changed:
        return pull(ctx, ident, slug, key, remote, packed)

    # Either both sides moved since the last sync, or this is a first run with
    # no state to compare against. Newest wins; the loser survives in backups.
    if local.mtime >= parse_time(remote["updated_at"]):
        warn(f"{ident}: both sides changed, local is newer -- uploading")
        return push(ctx, ident, key, packed, remote["rom_id"])
    warn(f"{ident}: both sides changed, server is newer -- restoring")
    return pull(ctx, ident, slug, key, remote, packed)


def push(ctx: Context, ident: str, key: str, packed: Packed, rom_id: int) -> None:
    adapter = ctx.adapter
    name = adapter.remote_name(key)
    log(f"{ident}: uploading {packed.files} file(s), {packed.size:,} bytes -> {name}")
    if ctx.args.dry_run:
        return

    saved = ctx.romm.upload(
        rom_id=rom_id,
        emulator=adapter.name,
        filename=name,
        blob=packed.blob,
        history=ctx.args.history,
    )
    # RomM sanitizes upload filenames. If it renamed this one, the key won't
    # round-trip and the save would look server-only on the next run, so say so
    # rather than quietly flapping between upload and restore.
    if adapter.key_for(saved.get("file_name", "")) != key:
        warn(f"{ident}: RomM stored this as {saved.get('file_name')!r}")

    remember(ctx, ident, packed.content_hash, saved.get("content_hash"))
    if saved.get("content_hash") != packed.content_hash:
        warn(
            f"{ident}: server hash {saved.get('content_hash')} "
            f"!= local {packed.content_hash}"
        )


def pull(
    ctx: Context,
    ident: str,
    slug: str,
    key: str,
    remote: dict,
    packed: Packed | None,
) -> None:
    adapter = ctx.adapter
    rom = next((r for r in ctx.roms if r["id"] == remote["rom_id"]), None)
    target = adapter.target_for(slug, key, rom)
    if target is None:
        log(f"{ident}: server has a save but there's no local profile for it")
        return

    log(f"{ident}: restoring {remote['file_name']} ({remote['file_size_bytes']:,} B)")
    if ctx.args.dry_run:
        return

    blob = ctx.romm.download(remote["id"])
    if packed is not None:
        saved_to = backup(adapter.name, adapter.remote_name(key), packed.blob)
        log(f"{ident}: previous local save backed up to {saved_to}")

    adapter.unpack(blob, target)
    remember(ctx, ident, adapter.pack(target).content_hash, remote.get("content_hash"))


def main() -> int:
    global verbose

    parser = argparse.ArgumentParser(
        prog="romm-save-sync",
        description="Sync Citra, Dolphin, Eden, RetroArch and RPCS3 saves with RomM.",
    )
    parser.add_argument(
        "--only",
        choices=sorted(ADAPTERS),
        action="append",
        help="sync just this emulator (repeatable; default is all of them)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="report what would be transferred, change nothing",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="sync even while the emulator is running (risks a torn save)",
    )
    parser.add_argument(
        "--history",
        type=int,
        default=int(os.environ.get("ROMM_SAVE_SYNC_HISTORY", "0")),
        help=(
            "keep N revisions per save server-side instead of one row updated "
            "in place; RomM deletes revisions past N (default: 0, never delete)"
        ),
    )
    parser.add_argument(
        "--verbose", action="store_true", help="log in-sync and unmatched saves too"
    )
    args = parser.parse_args()
    verbose = args.verbose

    url = os.environ.get("ROMM_URL")
    token = os.environ.get("ROMM_TOKEN")
    if not url or not token:
        print(
            f"error: ROMM_URL and ROMM_TOKEN must be set "
            f"(see {CONFIG_DIR / 'config.env'})",
            file=sys.stderr,
        )
        return 2

    romm = Romm(url, token)
    library = Library(romm)
    state = load_state()

    for name in args.only or sorted(ADAPTERS):
        try:
            sync_adapter(ADAPTERS[name], romm, library, state, args)
        except RommError as exc:
            fail(f"{name}: {exc}")

    if not args.dry_run:
        write_state(state)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
