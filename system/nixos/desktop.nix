{
  config,
  lib,
  pkgs,
  ...
}:
with pkgs;
let
  cfg = config.dusk.system.nixos.desktop;

  inherit (config.dusk) username;
  inherit (config.dusk.folders) home;
  inherit (lib) mkForce mkIf;

  terminal = config.dusk.terminal.default;
in
{
  imports = [
    ./gaming
    ./gnome
    ./hyprland
  ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        # Enable Wayland support on most Electron applications
        NIXOS_OZONE_WL = "1";

        # Enable newer freetype features
        FREETYPE_PROPERTIES = "truetype:interpreter-version=40";

        BROWSER = config.dusk.defaults.browser;
        TERMINAL = terminal;

        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        XDG_SESSION_TYPE = "wayland";
      };

      systemPackages =
        with pkgs;
        [
          discord
          easyeffects
          element-desktop
          firefox
          fractal
          helvum
          inkscape
          obs-studio
          obsidian
          qpwgraph
          telegram-desktop
          todoist-electron
          vlc
          wl-clipboard-rs
          zed-editor

          # Fonts
          cantarell-fonts
          dejavu_fonts
          noto-fonts
          source-code-pro
          source-sans
        ]
        ++ optionals config.dusk.system.nixos.virtualisation.libvirt.enable [
          (virt-manager.overrideAttrs (old: {
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.wrapGAppsHook ];
            buildInputs = lib.lists.subtractLists [ pkgs.wrapGAppsHook ] old.buildInputs ++ [
              pkgs.gst_all_1.gst-plugins-base
              pkgs.gst_all_1.gst-plugins-good
            ];
          }))
        ];
    };

    fonts.fontconfig = {
      enable = true;

      antialias = true;

      hinting = {
        enable = true;
        autohint = false;
        style = "slight";
      };

      subpixel = {
        lcdfilter = "default";
        rgba = "rgb";
      };
    };

    hardware.graphics.enable = true;

    programs.gnupg.agent.pinentryPackage = pkgs.pinentry-all;

    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = mkForce false;

      pipewire = {
        enable = true;
        socketActivation = true;

        alsa = {
          enable = true;
          support32Bit = true;
        };

        jack.enable = true;
        pulse.enable = true;
      };

      syncthing = {
        enable = true;

        user = username;
        dataDir = "${home}/Sync";
      };
    };
  };
}
