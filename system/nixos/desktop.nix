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
  inherit (lib) mkIf optionals;
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
        TERMINAL = config.dusk.defaults.terminal;
      };

      systemPackages =
        with pkgs;
        [
          alsa-utils
          google-chrome
          discord
          easyeffects
          element-desktop
          firefox
          fractal
          helvum
          inkscape
          obs-studio
          obsidian
          pavucontrol
          simplex-chat-desktop
          streamlink-twitch-gui-bin
          todoist-electron
          vlc
          vscode
          wl-clipboard-rs
          zed-editor

          # Fonts
          cantarell-fonts
          dejavu_fonts
          noto-fonts
          source-code-pro
          source-sans
        ]
        ++ optionals (config.dusk.terminal.flavor == "alacritty") [ alacritty ]
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

    hardware = {
      graphics.enable = true;
      pulseaudio.enable = false;
    };

    programs.gnupg.agent.pinentryPackage = pkgs.pinentry-all;

    security.rtkit.enable = true;

    services = {
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
