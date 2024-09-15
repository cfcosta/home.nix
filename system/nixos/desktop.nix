{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos.desktop;

  inherit (config.dusk) username;
  inherit (config.dusk.folders) home;
  inherit (lib) mkIf optionals;
in
{
  imports = [ ./cosmic ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
      };

      systemPackages =
        with pkgs;
        [
          anytype
          astroid
          bitwarden
          brave
          discord
          easyeffects
          element-desktop
          firefox
          fractal
          helvum
          mangohud
          moonlight-qt
          mullvad-browser
          obs-studio
          streamlink-twitch-gui-bin
          tdesktop
          todoist-electron
          tor-browser
          wl-clipboard
          zed-editor

          # Fonts
          cantarell-fonts
          dejavu_fonts
          source-code-pro
          source-sans
        ]
        ++ optionals cfg.alacritty.enable [ alacritty ]
        ++ optionals config.dusk.system.nixos.virtualisation.libvirt.enable [ virt-manager ];
    };

    hardware = {
      graphics.enable = true;
      pulseaudio.enable = false;
    };

    programs = {
      gnupg.agent.pinentryPackage = pkgs.pinentry-all;
      steam.enable = true;
    };

    security.rtkit.enable = true;

    services = {
      sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };

      pipewire = {
        enable = true;

        pulse.enable = true;
        jack.enable = true;
      };

      syncthing = {
        enable = true;

        user = username;
        dataDir = "${home}/Sync";
      };
    };
  };
}
