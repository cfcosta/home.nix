{
  config,
  lib,
  pkgs,
  ...
}:
{
  config.home-manager.users.${config.dusk.username} = {
    home.packages = [ pkgs.romm-save-sync ];

    # Mirror Eden (Switch), RPCS3 (PS3), Dolphin (GameCube and Wii) and
    # RetroArch (everything else) saves into RomM on the homelab VM.
    #
    # RomM only learns a save exists through its API — no scan reads the
    # assets directory — and its own device-sync modes handle single flat
    # files only (the folder watcher skips non-files; the SSH puller lists
    # one level of regular files). Eden, RPCS3 and Dolphin's Wii half keep a
    # DIRECTORY per save, so those ship as a zip, the shape RomM hashes
    # member-wise and can therefore compare without a download. RetroArch and
    # Dolphin's GameCube half already write one flat file per game, so those
    # go up verbatim and stay loadable by RomM's own web player.
    #
    # A timer rather than a path unit: the tool refuses to touch a save while
    # its emulator is running (a restore landing under a live Eden is how
    # cloud sync eats a save), so the useful moment is a few minutes AFTER
    # quitting, not the instant a file changes.
    systemd.user.services.romm-save-sync = {
      Unit.Description = "Mirror emulator saves to RomM";

      Service = {
        Type = "oneshot";

        # Citra names 3DS saves by title id and Dolphin names GameCube and Wii
        # ones by game id; nothing on disk, and no field in RomM, says which
        # game either belongs to. So the sync reads the id back out of each
        # dump's own header — NCSD for a 3DS cart, the disc header for a
        # GameCube or Wii image, through whichever container it is packed in.
        # Only the header is read, so a 4 GiB dump costs nothing.
        Environment = [ "ROMM_SAVE_SYNC_ROMS=${config.dusk.system.nixos.desktop.emulation.romsDirectory}" ];

        # ROMM_URL and the rmm_ client token live in a mode-600 file outside
        # the store and the repo, same as jobcrawler's daemon.env.
        # Rotate the token by editing that file; no rebuild.
        EnvironmentFile = "%h/.config/romm-save-sync/config.env";

        ExecStart = lib.getExe pkgs.romm-save-sync;
      };
    };

    systemd.user.timers.romm-save-sync = {
      Unit.Description = "Mirror emulator saves to RomM";

      Timer = {
        # Persistent so a machine that was asleep at the scheduled tick syncs
        # on resume instead of waiting out a full interval.
        OnBootSec = "3min";
        OnUnitActiveSec = "5min";
        Persistent = true;
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}
