"""Two-way sync of directory-shaped emulator saves with RomM.

RomM stores one flat FILE per save, and only ever learns that a save exists
through the API: `scan_save()` is called from the upload endpoint alone, and no
library scan looks at asset files on disk. Its own device-sync modes don't help
either -- the folder watcher skips anything that isn't a file, and the SSH
puller lists a single level of regular files. Eden and RPCS3 both keep a
DIRECTORY per save, so neither fits any of that.

This bridges the two by shipping each save directory as a zip. RomM hashes zip
uploads member-wise rather than over the container bytes (see
`_compute_zip_hash` in handler/filesystem/assets_handler.py), which is the
detail that makes the whole thing work: the server-side `content_hash` is
reproducible here, so both sides can be compared for equality without
downloading anything, and a rebuilt-but-identical zip doesn't look like a
change just because its container bytes shifted.

Safety rules this follows, in order of importance:

  * Never touch a save while its emulator is running. A restore landing under a
    live emulator is how cloud sync eats a save file.
  * Never overwrite local state without first writing a zip of it to the backup
    directory. Every destructive step is recoverable from there.
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
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

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

# RomM appends " [YYYY-MM-DD_HH-MM-SS]" to the filename when a save is uploaded
# with a slot, which is how history mode keeps revisions apart.
DATETIME_TAG = re.compile(r" \[\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\]$")
TITLE_ID = re.compile(r"^[0-9A-Fa-f]{16}$")

failures = 0


def log(msg: str) -> None:
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
        # The roms listing is paginated (LimitOffsetPage); a library this size
        # fits in one page well under the endpoint's 10k cap.
        page = self._json("/roms", platform_ids=platform_id, limit=10000)
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
            # No slot: the filename stays exactly `<key>.zip` and the existing
            # row is updated in place. Nothing is ever deleted server-side.
            params = {"rom_id": rom_id, "emulator": emulator, "overwrite": "true"}

        boundary = "----romm-save-sync-boundary"
        body = b"".join(
            [
                f"--{boundary}\r\n".encode(),
                (
                    'Content-Disposition: form-data; name="saveFile"; '
                    f'filename="{filename}"\r\n'
                ).encode(),
                b"Content-Type: application/zip\r\n\r\n",
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


# --------------------------------------------------------------------------
# Archive helpers
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


def content_hash(members: list[tuple[str, bytes]]) -> str:
    """Reproduce RomM's zip content hash for the same set of members.

    Must stay byte-identical to `_compute_zip_hash`: md5 of "name:md5hex" lines
    joined by newlines, members in sorted name order.
    """
    lines = [
        f"{name}:{hashlib.md5(blob, usedforsecurity=False).hexdigest()}"
        for name, blob in members
    ]
    combined = "\n".join(lines)
    return hashlib.md5(combined.encode(), usedforsecurity=False).hexdigest()


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


def backup(emulator: str, key: str, members: list[tuple[str, bytes]]) -> Path:
    """Snapshot the current local save before anything overwrites it."""
    stamp = datetime.now(timezone.utc).astimezone().strftime("%Y-%m-%d_%H-%M-%S")
    directory = STATE_DIR / "backups" / emulator
    directory.mkdir(parents=True, exist_ok=True)
    path = directory / f"{key}-{stamp}.zip"
    path.write_bytes(build_zip(members))
    return path


def restore(blob: bytes, target: Path) -> None:
    """Replace `target`'s contents with the archive, swapping directories.

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


# --------------------------------------------------------------------------
# Emulator adapters
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class SaveDir:
    key: str
    path: Path

    @property
    def mtime(self) -> datetime:
        newest = self.path.stat().st_mtime
        for path in self.path.rglob("*"):
            if path.is_file():
                newest = max(newest, path.stat().st_mtime)
        return datetime.fromtimestamp(newest, tz=timezone.utc)


class Adapter:
    name: str
    platform_slug: str
    processes: tuple[str, ...]

    def discover(self) -> list[SaveDir]:
        raise NotImplementedError

    def resolve(self, save: SaveDir, roms: list[dict]) -> int | None:
        """Map a local save directory to a RomM rom id."""
        raise NotImplementedError

    def target_for(self, key: str) -> Path | None:
        """Where a save that only exists server-side should be restored to."""
        raise NotImplementedError


def normalize(name: str) -> str:
    return re.sub(r"[^a-z0-9]", "", name.lower())


# PARAM.SFO's TITLE names the SAVE, not the game -- "Dragon's Crown Save Data"
# for a ROM RomM simply calls "Dragon's Crown". Longest suffix first, so
# "savedata" wins over the "data" that also matches it.
SAVE_SUFFIXES = ("savedata", "gamedata", "playdata", "savefile", "save", "data")


def strip_save_suffix(value: str) -> str:
    for suffix in SAVE_SUFFIXES:
        if value.endswith(suffix) and len(value) > len(suffix):
            return value[: -len(suffix)]
    return value


class Eden(Adapter):
    """Eden (Switch): nand/user/save/<space-id>/<user-uuid>/<title-id>/."""

    name = "eden"
    platform_slug = "switch"
    processes = ("eden", "eden-cli")
    root = HOME / ".local/share/eden/nand/user/save"

    def discover(self) -> list[SaveDir]:
        found: dict[str, SaveDir] = {}
        for path in sorted(self.root.glob("*/*/*")):
            if not path.is_dir() or not TITLE_ID.match(path.name):
                continue
            key = path.name.upper()
            save = SaveDir(key=key, path=path)
            # One title under two user profiles is possible; the freshest one
            # is the save actually being played.
            if key in found and found[key].mtime >= save.mtime:
                warn(f"eden: {key} exists under several profiles, using the newest")
                continue
            found[key] = save
        return list(found.values())

    def resolve(self, save: SaveDir, roms: list[dict]) -> int | None:
        # Switch ROM filenames carry the title id in brackets -- that's the
        # same identifier RomM matches against its TitleDB index, so it is the
        # authoritative link between a save directory and a rom.
        for rom in roms:
            if f"[{save.key}]" in (rom.get("fs_name") or "").upper():
                return rom["id"]
        return None

    def target_for(self, key: str) -> Path | None:
        profiles = sorted(p for p in self.root.glob("*/*") if p.is_dir())
        if not profiles:
            return None
        return profiles[-1] / key


class Rpcs3(Adapter):
    """RPCS3 (PS3): dev_hdd0/home/<user>/savedata/<PRODUCT>-<SLOT>/."""

    name = "rpcs3"
    platform_slug = "ps3"
    processes = ("rpcs3",)
    root = HOME / ".config/rpcs3/dev_hdd0/home"

    def discover(self) -> list[SaveDir]:
        saves = []
        for path in sorted(self.root.glob("*/savedata/*")):
            if path.is_dir() and not path.name.startswith("."):
                saves.append(SaveDir(key=path.name, path=path))
        return saves

    def resolve(self, save: SaveDir, roms: list[dict]) -> int | None:
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

    def target_for(self, key: str) -> Path | None:
        users = sorted(p for p in self.root.glob("*") if (p / "savedata").is_dir())
        if not users:
            return None
        return users[0] / "savedata" / key


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


ADAPTERS = {adapter.name: adapter for adapter in (Eden(), Rpcs3())}


# --------------------------------------------------------------------------
# Sync
# --------------------------------------------------------------------------


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


def key_from_filename(filename: str) -> str:
    stem = filename[:-4] if filename.lower().endswith(".zip") else filename
    return DATETIME_TAG.sub("", stem)


def load_state() -> dict:
    path = STATE_DIR / "state.json"
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return {}


def write_state(state: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    path = STATE_DIR / "state.json"
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(state, indent=2, sort_keys=True))
    tmp.replace(path)


def sync_adapter(adapter: Adapter, romm: Romm, state: dict, args) -> None:
    busy = emulator_running(adapter.processes)
    if busy and not args.force:
        log(f"{adapter.name}: {busy} is running -- skipping (--force overrides)")
        return

    platforms = {p["fs_slug"]: p for p in romm.platforms()}
    platform = platforms.get(adapter.platform_slug)
    if not platform:
        log(f"{adapter.name}: no '{adapter.platform_slug}' platform in RomM, skipping")
        return

    roms = romm.roms(platform["id"])
    local = {save.key: save for save in adapter.discover()}

    # Keep only the newest server-side revision per key. In history mode there
    # are several rows behind one save; in plain mode there's exactly one.
    remote: dict[str, dict] = {}
    for save in romm.saves(platform["id"]):
        if save.get("emulator") != adapter.name:
            continue
        key = key_from_filename(save["file_name"])
        current = remote.get(key)
        if current is None or parse_time(save["updated_at"]) > parse_time(
            current["updated_at"]
        ):
            remote[key] = save

    if not local and not remote:
        log(f"{adapter.name}: nothing to sync")
        return

    for key in sorted(set(local) | set(remote)):
        try:
            sync_one(
                adapter, romm, state, args, key, local.get(key), remote.get(key), roms
            )
        except RommError as exc:
            fail(f"{adapter.name}/{key}: {exc}")
        except OSError as exc:
            fail(f"{adapter.name}/{key}: {exc}")


def sync_one(
    adapter: Adapter,
    romm: Romm,
    state: dict,
    args,
    key: str,
    local: SaveDir | None,
    remote: dict | None,
    roms: list[dict],
) -> None:
    tag = f"{adapter.name}/{key}"
    previous = state.get(tag, {})

    members = read_tree(local.path) if local else []
    if local and not members:
        # An emulator creates the save directory on first launch and only fills
        # it on the first in-game save, so an empty one is a normal steady
        # state. Treat it as no local save at all rather than bailing out: a
        # save that exists only on the server has to be able to restore INTO
        # that directory, which an early return would block forever.
        local = None
        members = []

    if local is None and remote is None:
        if args.verbose:
            log(f"{tag}: local save directory is empty and the server has none")
        return

    local_hash = content_hash(members) if local else None

    if remote is None:
        rom_id = adapter.resolve(local, roms)  # type: ignore[arg-type]
        if rom_id is None:
            log(f"{tag}: no matching ROM in RomM, skipping")
            return
        return push(adapter, romm, state, args, key, local, members, local_hash, rom_id)

    if local is None:
        return pull(adapter, romm, state, args, key, remote, None)

    if local_hash == remote.get("content_hash"):
        state[tag] = {
            "local": local_hash,
            "server": remote.get("content_hash"),
            "at": datetime.now(timezone.utc).isoformat(),
        }
        if args.verbose:
            log(f"{tag}: in sync")
        return

    local_changed = previous.get("local") != local_hash
    server_changed = previous.get("server") != remote.get("content_hash")

    if local_changed and not server_changed:
        return push(
            adapter,
            romm,
            state,
            args,
            key,
            local,
            members,
            local_hash,
            remote["rom_id"],
        )
    if server_changed and not local_changed:
        return pull(adapter, romm, state, args, key, remote, members)

    # Either both sides moved since the last sync, or this is a first run with
    # no state to compare against. Newest wins; the loser survives in backups.
    if local.mtime >= parse_time(remote["updated_at"]):
        warn(f"{tag}: both sides changed, local is newer -- uploading")
        return push(
            adapter,
            romm,
            state,
            args,
            key,
            local,
            members,
            local_hash,
            remote["rom_id"],
        )
    warn(f"{tag}: both sides changed, server is newer -- restoring")
    return pull(adapter, romm, state, args, key, remote, members)


def push(
    adapter: Adapter,
    romm: Romm,
    state: dict,
    args,
    key: str,
    local: SaveDir,
    members: list[tuple[str, bytes]],
    local_hash: str,
    rom_id: int,
) -> None:
    tag = f"{adapter.name}/{key}"
    size = sum(len(blob) for _, blob in members)
    log(f"{tag}: uploading {len(members)} files ({size:,} bytes) to rom {rom_id}")
    if args.dry_run:
        return

    saved = romm.upload(
        rom_id=rom_id,
        emulator=adapter.name,
        filename=f"{key}.zip",
        blob=build_zip(members),
        history=args.history,
    )
    # Trust the server's own hash rather than the locally computed one, so a
    # mismatch in the hashing contract shows up as repeated uploads instead of
    # silently marking things in sync.
    state[tag] = {
        "local": local_hash,
        "server": saved.get("content_hash"),
        "at": datetime.now(timezone.utc).isoformat(),
    }
    if saved.get("content_hash") != local_hash:
        warn(f"{tag}: server hash {saved.get('content_hash')} != local {local_hash}")


def pull(
    adapter: Adapter,
    romm: Romm,
    state: dict,
    args,
    key: str,
    remote: dict,
    members: list[tuple[str, bytes]] | None,
) -> None:
    tag = f"{adapter.name}/{key}"
    target = adapter.target_for(key)
    if target is None:
        log(f"{tag}: server has a save but there's no local profile to restore into")
        return

    log(f"{tag}: restoring {remote['file_name']} ({remote['file_size_bytes']:,} bytes)")
    if args.dry_run:
        return

    blob = romm.download(remote["id"])
    if members:
        saved_to = backup(adapter.name, key, members)
        log(f"{tag}: previous local save backed up to {saved_to}")

    restore(blob, target)
    state[tag] = {
        "local": content_hash(read_tree(target)),
        "server": remote.get("content_hash"),
        "at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="romm-save-sync",
        description="Sync Eden and RPCS3 save directories with RomM.",
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
    parser.add_argument("--verbose", action="store_true", help="log in-sync saves too")
    args = parser.parse_args()

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
    state = load_state()
    selected = args.only or sorted(ADAPTERS)

    for name in selected:
        adapter = ADAPTERS[name]
        try:
            sync_adapter(adapter, romm, state, args)
        except RommError as exc:
            fail(f"{name}: {exc}")

    if not args.dry_run:
        write_state(state)
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
