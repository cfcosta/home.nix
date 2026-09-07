# RomM launchers for Moonshine

Only `machines/battlecruiser/romm-moonshine.nix` enables this exporter. Other
installations keep their standalone Eden launcher and need no RomM server.

The system service `moonshine-romm-library` reads `ROMM_URL` and `ROMM_TOKEN`
from the existing `~/.config/romm-save-sync/config.env`. It only reads RomM's
platform, ROM and cover endpoints. Credentials and ROMs never enter the Nix
store. The local library is `dusk.system.nixos.desktop.emulation.romsDirectory`.

Each locally available Switch base game becomes a desktop entry with its
RomM title and cached cover. Eden starts fullscreen with `-f -g`, and both SDL
audio-driver variables force PulseAudio for streaming. Base dumps must have a
bracketed 16-digit Switch title ID ending in `000` in their filename. Updates,
DLC, missing dumps and ambiguous folders are skipped and logged. A folder
containing both an NSP and an XCI base dump is ambiguous; retain one base dump
there to export it. Missing covers abort the refresh, preserving the previous
complete listing.

Refresh runs before Moonshine starts and every six hours. A failed or timed-out
refresh does not prevent Moonshine starting with its cached listing. On the
first run, RomM and the local library must be available to populate that cache.
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
