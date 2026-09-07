# RomM launchers for Moonshine

Only `machines/battlecruiser/romm-moonshine.nix` enables this exporter. Other
installations keep their standalone Eden/RPCS3 launchers and need no RomM server.

The system service `moonshine-romm-library` reads `ROMM_URL` and `ROMM_TOKEN`
from the existing `~/.config/romm-save-sync/config.env`. It only reads RomM's
platform, ROM and cover endpoints. Credentials and ROMs never enter the Nix
store. The local library is `dusk.system.nixos.desktop.emulation.romsDirectory`.

Each locally available Switch or PS3 base game becomes a desktop entry with its
RomM title and cached cover. Eden starts fullscreen with `-f -g`; RPCS3 uses
`--no-gui --fullscreen` with the game's ISO or extracted disc directory. Both
SDL audio-driver variables force PulseAudio for streaming SDL backends.

Switch base dumps must have a
bracketed 16-digit Switch title ID ending in `000` in their filename. Updates,
DLC, missing dumps and ambiguous folders are skipped and logged. A folder
containing both an NSP and an XCI base dump is ambiguous; retain one base dump
there to export it. Missing covers abort the refresh, preserving the previous
complete listing.

PS3 supports a single ISO (directly or in a game folder), or an extracted disc
containing `PS3_GAME/USRDIR/EBOOT.BIN` and `PS3_GAME/PARAM.SFO`. Folders with more
than one boot target are skipped. PKG installers, updates and DLC are never
launched or installed by the exporter. Existing RPCS3 firmware, keys, installed
updates and per-game settings remain in use. PSN games available only as PKG
installers are not exported.

Refresh runs before Moonshine starts and every six hours. A failed or timed-out
refresh does not prevent Moonshine starting with its cached listing. On the
first run, both RomM platforms and the local `switch` and `ps3` directories
must be available to populate that cache. Failure on either platform preserves
the previous combined listing.
The exporter never restarts Moonshine or launches games itself. Moonshine scans
only at startup, so new/removed games appear after its next restart.

After applying the NixOS configuration, inspect the export with:

```sh
systemctl status moonshine-romm-library
journalctl -u moonshine-romm-library -n 30
ls /var/lib/moonshine-romm/current/
```

To refresh immediately and load the new listing **when no stream is active**:

```sh
sudo systemctl start moonshine-romm-library
sudo systemctl restart moonshine
```

State lives under `/var/lib/moonshine-romm`: an atomic `current` symlink points
to an immutable launcher generation, and `covers` holds cached image versions.
Old generations and covers are retained so concurrent scans and existing
Moonshine processes can still use their paths. Unchanged exports reuse them.
To reclaim obsolete cache versions, stop Moonshine and the exporter/timer,
remove this directory, then start the exporter/timer and Moonshine again while
RomM is reachable.

Run tests with `python3 -m unittest discover -s packages/romm-moonshine -v`.
The Nix package also runs them as part of its build.
