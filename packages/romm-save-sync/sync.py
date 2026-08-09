"""Two-way sync of emulator saves with RomM.

RomM only ever learns that a save exists through its API: `scan_save()` is
called from the upload endpoint alone, and no library scan looks at asset files
on disk. Its own device-sync modes don't close the gap either -- the folder
watcher skips anything that isn't a file, and the SSH puller lists a single
level of regular files.

Two save shapes are handled, because the emulators disagree:

  * Eden (Switch), RPCS3 (PS3) and Citra (3DS, under RetroArch) keep a
    DIRECTORY per save, which RomM has no concept of. Those are shipped as a
    zip. RomM hashes zip uploads member-wise rather than over the container
    bytes (`_compute_zip_hash` in handler/filesystem/assets_handler.py), which
    is what makes this work: the server-side content_hash is reproducible
    here, so both sides compare for equality without downloading anything, and
    a rebuilt-but-identical archive doesn't look like a change just because
    its container bytes shifted.
  * RetroArch writes a single flat file per game. Those go up verbatim -- no
    zip -- so the save stays readable by anything else that speaks the format,
    RomM's own web player included. RomM hashes those as a plain md5
    (`_compute_file_hash`), which is reproduced here for the same reason.

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
        members = read_tree(path)
        blob = build_zip(members) if members else b""
        size = sum(len(data) for _, data in members)
        return Packed(blob, zip_content_hash(members), len(members), size)

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
        blob = path.read_bytes()
        return Packed(blob, file_content_hash(blob), 1, len(blob))

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
    # Every platform RomM holds ROMs for that libretro has a core for. Switch
    # and PS3 are absent because no core exists; eden and rpcs3 cover them.
    platform_slugs = (
        "3ds",
        "gb",
        "gba",
        "gbc",
        "nds",
        "ngc",
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
        # unmatched folder (Dolphin's shared memory cards, say) is permanent,
        # and paying thousands of rom records for it on every tick is not.
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


def ncsd_title_id(path: Path) -> str | None:
    """Title id from a 3DS dump, straight or inside a zip.

    NCSD (a .cci/.3ds cart dump) carries "NCSD" at 0x100 and the media/title id
    as a little-endian u64 at 0x108. Only the header is read, so a 4 GiB dump
    costs almost nothing to identify.
    """
    try:
        if path.suffix.lower() == ".zip":
            with zipfile.ZipFile(path) as archive:
                names = [n for n in archive.namelist() if not n.endswith("/")]
                if not names:
                    return None
                with archive.open(names[0]) as handle:
                    head = handle.read(0x200)
        else:
            with open(path, "rb") as handle:
                head = handle.read(0x200)
    except (OSError, zipfile.BadZipFile):
        return None

    if len(head) < 0x110 or head[0x100:0x104] != b"NCSD":
        return None
    return f"{struct.unpack_from('<Q', head, 0x108)[0]:016X}"


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
    adapter.name: adapter for adapter in (Citra(), Eden(), RetroArch(), Rpcs3())
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


def emulator_running(names: tuple[str, ...]) -> str | None:
    for entry in Path("/proc").iterdir():
        if not entry.name.isdigit():
            continue
        try:
            comm = (entry / "comm").read_text().strip()
        except OSError:
            continue  # process exited between listing and reading
        if comm in names:
            return comm
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
        description="Sync Citra, Eden, RetroArch and RPCS3 saves with RomM.",
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
