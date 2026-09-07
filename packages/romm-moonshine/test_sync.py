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

    def roms(self, platform):
        return [rom for rom in self.items if rom["platform_fs_slug"] == platform]

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
        self.ps3 = self.root / "ps3"
        self.ps3.mkdir()
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

    def ps3_game(self, name="Dragon's Crown", ident=2, nested=False):
        location = self.ps3 / name if nested else self.ps3
        location.mkdir(exist_ok=True)
        iso = location / f"{name}.iso"
        iso.touch()
        return {
            "id": ident,
            "name": name,
            "fs_name": location.name if nested else iso.name,
            "platform_fs_slug": "ps3",
            "path_cover_large": f"/assets/{ident}/big.png?ts=1",
        }, iso

    def test_exports_switch_and_ps3_with_their_own_launchers_and_covers(self):
        switch, _ = self.game()
        ps3, iso = self.ps3_game()
        self.assertEqual(
            sync.refresh(FakeRomm([switch, ps3]), self.root, self.output), 2
        )
        entry = (self.output / "current" / "2.desktop").read_text()
        self.assertIn("Name=Dragon's Crown (PS3)", entry)
        raw = next(line[5:] for line in entry.splitlines() if line.startswith("Exec="))
        self.assertEqual(
            shlex.split(raw),
            [
                "/run/current-system/sw/bin/env",
                "SDL_AUDIODRIVER=pulseaudio",
                "SDL_AUDIO_DRIVER=pulseaudio",
                "/run/current-system/sw/bin/rpcs3",
                "--no-gui",
                "--fullscreen",
                str(iso),
            ],
        )
        icon = Path(
            next(line[5:] for line in entry.splitlines() if line.startswith("Icon="))
        )
        self.assertEqual(icon.read_bytes(), JPEG)

    def test_ps3_nested_iso_ignores_update_packages(self):
        rom, iso = self.ps3_game(nested=True)
        updates = iso.parent / "update"
        updates.mkdir()
        (updates / "patch.pkg").touch()
        self.assertEqual(sync.local_game(rom, self.root), iso)
        iso.unlink()
        self.assertIsNone(sync.local_game(rom, self.root))

    def test_ps3_extracted_disc_and_ambiguous_dumps(self):
        rom, iso = self.ps3_game(nested=True)
        disc = iso.parent / "disc"
        boot = disc / "PS3_GAME/USRDIR/EBOOT.BIN"
        boot.parent.mkdir(parents=True)
        boot.touch()
        (disc / "PS3_GAME/PARAM.SFO").touch()
        self.assertIsNone(sync.local_game(rom, self.root))
        iso.unlink()
        self.assertEqual(sync.local_game(rom, self.root), disc)
        boot.unlink()
        self.assertIsNone(sync.local_game(rom, self.root))

    def test_ps3_escaping_paths_and_installer_are_not_launched(self):
        rom, iso = self.ps3_game()
        for name in ("../outside.iso", str(iso), "install.pkg"):
            with self.subTest(name=name):
                self.assertIsNone(sync.local_game({**rom, "fs_name": name}, self.root))
        outside = Path(self.temp.name) / "outside.iso"
        outside.touch()
        iso.unlink()
        iso.symlink_to(outside)
        self.assertIsNone(sync.local_game(rom, self.root))

    def test_unavailable_ps3_library_preserves_combined_listing(self):
        switch, _ = self.game()
        ps3, iso = self.ps3_game()
        api = FakeRomm([switch, ps3])
        sync.refresh(api, self.root, self.output)
        previous = (self.output / "current").resolve()
        iso.unlink()
        self.ps3.rmdir()
        with self.assertRaises(OSError):
            sync.refresh(api, self.root, self.output)
        self.assertEqual((self.output / "current").resolve(), previous)
        self.assertEqual(len(self.entries()), 2)

    def test_same_title_on_different_platforms_keeps_switch_title_stable(self):
        switch, _ = self.game()
        ps3, _ = self.ps3_game(name="Game")
        sync.refresh(FakeRomm([switch, ps3]), self.root, self.output)
        self.assertIn(
            "Name=Game (Switch)\n", (self.output / "current/1.desktop").read_text()
        )
        self.assertIn(
            "Name=Game (PS3)\n", (self.output / "current/2.desktop").read_text()
        )

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
            self.assertEqual([r["id"] for r in api.roms("switch")], [1, 2])
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
            api.roms("switch")

    def test_missing_platform_is_failure(self):
        api = sync.Romm("https://romm.example", "secret")
        with (
            patch.object(api, "get", return_value=b"[]"),
            self.assertRaises(ValueError),
        ):
            api.roms("switch")

    def test_selects_ps3_platform_id_for_requests(self):
        api = sync.Romm("https://romm.example", "secret")
        with patch.object(
            api,
            "get",
            side_effect=[
                b'[{"id":21,"fs_slug":"switch"},{"id":29,"fs_slug":"ps3"}]',
                b'{"items":[{"id":2}],"total":1}',
            ],
        ) as get:
            self.assertEqual(api.roms("ps3"), [{"id": 2}])
            self.assertIn("platform_ids=29", get.call_args.args[0])

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
