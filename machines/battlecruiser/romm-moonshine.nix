{
  config,
  lib,
  pkgs,
  ...
}:
let
  desktop = config.dusk.system.nixos.desktop;
  username = config.dusk.username;
  home = config.users.users.${username}.home;
  exporter = pkgs.callPackage ../../packages/romm-moonshine { };
  stateDirectory = "/var/lib/moonshine-romm";
in
{
  config = lib.mkIf (desktop.moonshine.enable && desktop.emulation.enable) {
    dusk.system.nixos.desktop.moonshine.edenLauncher.enable = false;

    services.moonshine.settings.application_scanner = [
      {
        type = "desktop";
        directories = [ "${stateDirectory}/current" ];
      }
    ];

    # Wants, not Requires: cached games still work when RomM is offline.
    systemd.services.moonshine = {
      wants = [ "moonshine-romm-library.service" ];
      after = [ "moonshine-romm-library.service" ];
    };

    systemd.services.moonshine-romm-library = {
      description = "Export RomM Switch games and covers for Moonshine";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = username;
        StateDirectory = "moonshine-romm";
        StateDirectoryMode = "0750";
        # Reuse the existing credentials, keeping them out of the Nix store.
        EnvironmentFile = "${home}/.config/romm-save-sync/config.env";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe exporter)
          "--roms-directory"
          desktop.emulation.romsDirectory
          "--output-directory"
          stateDirectory
        ];
        TimeoutStartSec = "60s";
        UMask = "0027";
      };
    };

    # Refresh the cache without restarting an active Moonshine stream. Its
    # scanner reads the new generation the next time the daemon starts.
    systemd.timers.moonshine-romm-library = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "6h";
      };
    };
  };
}
