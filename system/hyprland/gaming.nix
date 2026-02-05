{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.gaming;
  hytale = pkgs.fetchurl {
    url = "https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.flatpak";
    sha256 = "sha256-4DUP/hHgpbKvjRIF2ksxhtGFkvA9QSVOT4w+c4MXa+4=";
  };
in
{
  config = mkIf cfg.enable {
    boot.kernel.sysctl."vm.max_map_count" = 1048576;

    environment.systemPackages = with pkgs; [
      heroic
      mangohud
      moonlight-qt
    ];

    hardware = {
      graphics.enable = true;

      # Support for Xbox One/Series X Controllers
      xone.enable = true;
      xpadneo.enable = false;
    };

    home-manager.users.${config.dusk.username}.xdg.configFile."gamemode.ini".text = ''
      [general]
      softrealtime=on

      [cpu]
      pin_cores=no
    '';

    programs = {
      gamemode = {
        enable = true;
        enableRenice = true;
      };

      gamescope = mkIf cfg.gamescope.enable {
        enable = true;
        capSysNice = true;
      };

      steam = {
        enable = true;

        dedicatedServer.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;

        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        protontricks.enable = true;

        gamescopeSession = mkIf cfg.gamescope.enable {
          enable = true;

          env = {
            WLR_RENDERER = "vulkan";
            ENABLE_GAMESCOPE_WSI = "1";
          };

          args = [
            "--steam"
            "--adaptive-sync"
          ];
        };
      };
    };

    services.flatpak = {
      enable = true;

      packages = [
        {
          appId = "com.hypixel.HytaleLauncher";
          sha256 = "";
          bundle = "${hytale}";
        }
      ];
    };

    users.users.${config.dusk.username}.extraGroups = [ "gamemode" ];
  };
}
