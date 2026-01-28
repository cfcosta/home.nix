{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.gaming;
  xone-firmware = pkgs.xow_dongle-firmware.overrideAttrs (_old: rec {
    name = "xone-firmware";
    version = "045e_02e6";
    src = pkgs.fetchurl {
      url = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2015/12/20810869_8ce2975a7fbaa06bcfb0d8762a6275a1cf7c1dd3.cab";
      sha256 = "sha256-5jiKJ6dXVpIN5zryRo461V16/vWavDoLUICU4JHRnwg=";
    };
    unpackCmd = ''
      cabextract -F FW_ACC_00U.bin ${src}
    '';
    installPhase = ''
      mkdir -p $out/lib/firmware
      cp xow_dongle_045e_02e6.bin $out/lib/firmware/xone_dongle_02e6.bin
    '';
  });
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
      xone-firmware
    ];

    hardware = {
      graphics.enable = true;

      # Support for Xbox One/Series X Controllers
      xone.enable = true;
      xpadneo.enable = false;

      firmware = [ xone-firmware ];
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
