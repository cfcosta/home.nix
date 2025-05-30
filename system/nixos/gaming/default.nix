{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.gaming;
in
{
  imports = [ ./sunshine.nix ];

  config = mkIf cfg.enable {
    boot.kernel.sysctl."vm.max_map_count" = 1048576;

    environment.systemPackages = with pkgs; [
      mangohud
      moonlight-qt
      prismlauncher
    ];

    hardware = {
      graphics.enable = true;

      # Support for Xbox One Controllers
      xone.enable = true;
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
            WINE_FULLSCREEN_FSR = "1";
          };

          args = [
            "--steam"
            "--adaptive-sync"
          ];
        };
      };
    };

    users.users.${config.dusk.username}.extraGroups = [ "gamemode" ];
  };
}
