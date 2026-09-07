import json
import re
import shlex
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import sync

JPEG = b"\xff\xd8\xff\xe0cover"


class FakeRomm:
    def __init__(self, roms):
        self.items = roms
        self.downloads = 0

    def switch_roms(self):
        return self.items

    def get(self, path):
        self.downloads += 1
        return JPEG


class ExportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "roms"
        self.switch = self.root / "switch"
        self.switch.mkdir(parents=True)
        self.output = Path(self.temp.name) / "export"

    def game(self, name="Game", ident=1, title_id="0100152000022000"):
        folder = self.switch / f"{name} [{title_id}]"
        folder.mkdir()
        base = folder / f"{name} [{title_id}][v0].xci"
        base.touch()
        rom = {
            "id": ident,
            "name": name,
            "fs_name": folder.name,
            "platform_fs_slug": "switch",
            "path_cover_large": f"/assets/{ident}/big.png?ts=1",
        }
        return rom, base

    def entries(self):
        return sorted((self.output / "current").glob("*.desktop"))

    def test_launches_base_game_with_cover_fullscreen_and_stream_audio(self):
        rom, base = self.game("Pokémon: Let's Go! 100%")
        (base.parent / "Game [0100152000022800][v65536].nsp").touch()
        (base.parent / "DLC [0100152000023001][v0].nsp").touch()
        api = FakeRomm([rom])
        self.assertEqual(sync.refresh(api, self.root, self.output), 1)
        entry = self.entries()[0].read_text()
        self.assertIn("Name=Pokémon: Let's Go! 100% (Switch)", entry)
        # The desktop scanner unescapes values, splits Exec, then expands %%.
        raw = next(line[5:] for line in entry.splitlines() if line.startswith("Exec="))
        decoded = re.sub(
            r"\\(.)",
            lambda m: {"n": "\n", "r": "\r", "t": "\t", "s": " "}.get(m[1], m[1]),
            raw,
        )
        argv = [arg.replace("%%", "%") for arg in shlex.split(decoded)]
        self.assertEqual(
            argv,
            [
                "/run/current-system/sw/bin/env",
                "SDL_AUDIODRIVER=pulseaudio",
                "SDL_AUDIO_DRIVER=pulseaudio",
                "/run/current-system/sw/bin/eden",
                "-f",
                "-g",
                str(base),
            ],
        )
        icon = Path(
            next(line[5:] for line in entry.splitlines() if line.startswith("Icon="))
        )
        self.assertEqual(icon.suffix, ".jpg")  # RomM calls JPEGs big.png.
        self.assertEqual(icon.read_bytes(), JPEG)
        sync.refresh(api, self.root, self.output)
        self.assertEqual(api.downloads, 1)

    def test_updates_dlc_ambiguous_missing_and_external_paths_are_skipped(self):
        rom, base = self.game()
        base.unlink()
        (base.parent / "Update [0100152000022800].nsp").touch()
        (base.parent / "DLC [0100152000023001].nsp").touch()
        self.assertIsNone(sync.local_game(rom, self.root))
        base.touch()
        (base.parent / "Another [0100152000022000].nsp").touch()
        self.assertIsNone(sync.local_game(rom, self.root))
        self.assertIsNone(sync.local_game({**rom, "fs_name": "../escape"}, self.root))
        self.assertIsNone(sync.local_game({**rom, "fs_name": "/etc"}, self.root))
        outside = Path(self.temp.name) / "Outside [0100152000022000].xci"
        outside.touch()
        (self.switch / "escape.xci").symlink_to(outside)
        self.assertIsNone(sync.local_game({**rom, "fs_name": "escape.xci"}, self.root))

    def test_failure_preserves_previous_listing_and_covers(self):
        rom, _ = self.game()
        api = FakeRomm([rom])
        sync.refresh(api, self.root, self.output)
        old = (self.output / "current").resolve()
        newer, _ = self.game("New game", 2)
        api.items.append(newer)
        with (
            patch.object(api, "get", side_effect=OSError("offline")),
            self.assertRaises(OSError),
        ):
            sync.refresh(api, self.root, self.output)
        self.assertEqual((self.output / "current").resolve(), old)
        self.assertEqual(len(self.entries()), 1)
        self.assertTrue(old.is_dir())

    def test_success_removes_stale_entries_but_keeps_old_cover_paths(self):
        rom, _ = self.game()
        sync.refresh(FakeRomm([rom]), self.root, self.output)
        old_entry = self.entries()[0].read_text()
        previous = (self.output / "current").resolve()
        old_icon = Path(
            next(
                line[5:] for line in old_entry.splitlines() if line.startswith("Icon=")
            )
        )
        sync.refresh(FakeRomm([]), self.root, self.output)
        self.assertEqual(self.entries(), [])
        self.assertTrue(old_icon.exists())
        self.assertTrue(previous.is_dir())

    def test_missing_mount_does_not_erase_cache(self):
        rom, base = self.game()
        sync.refresh(FakeRomm([rom]), self.root, self.output)
        base.unlink()
        base.parent.rmdir()
        self.switch.rmdir()
        with self.assertRaises(OSError):
            sync.refresh(FakeRomm([rom]), self.root, self.output)
        self.assertEqual(len(self.entries()), 1)

    def test_duplicate_titles_remain_distinct(self):
        first, _ = self.game()
        second, _ = self.game(ident=2, title_id="0100187003A36000")
        sync.refresh(FakeRomm([first, second]), self.root, self.output)
        names = [
            next(
                line for line in p.read_text().splitlines() if line.startswith("Name=")
            )
            for p in self.entries()
        ]
        self.assertEqual(len(set(names)), 2)


class ApiTests(unittest.TestCase):
    def test_pagination(self):
        api = sync.Romm("https://romm.example", "secret")
        with patch.object(
            api,
            "get",
            side_effect=[
                json.dumps([{"id": 21, "fs_slug": "switch"}]).encode(),
                json.dumps({"items": [{"id": 1}], "total": 2}).encode(),
                json.dumps({"items": [{"id": 2}], "total": 2}).encode(),
            ],
        ) as get:
            self.assertEqual([r["id"] for r in api.switch_roms()], [1, 2])
            self.assertIn("offset=1", get.call_args.args[0])

    def test_incomplete_page_is_failure(self):
        api = sync.Romm("https://romm.example", "secret")
        with (
            patch.object(
                api,
                "get",
                side_effect=[
                    b'[{"id":21,"fs_slug":"switch"}]',
                    b'{"items":[],"total":1}',
                ],
            ),
            self.assertRaises(ValueError),
        ):
            api.switch_roms()

    def test_missing_platform_is_failure(self):
        api = sync.Romm("https://romm.example", "secret")
        with (
            patch.object(api, "get", return_value=b"[]"),
            self.assertRaises(ValueError),
        ):
            api.switch_roms()

    def test_cross_origin_requests_and_redirects_are_rejected(self):
        api = sync.Romm("https://romm.example", "secret")
        with self.assertRaises(ValueError):
            api.get("https://other.example/cover.png")
        self.assertIsNone(
            sync.NoRedirect().redirect_request(
                None, None, 302, "Found", {}, "https://other.example"
            )
        )


if __name__ == "__main__":
    unittest.main()
