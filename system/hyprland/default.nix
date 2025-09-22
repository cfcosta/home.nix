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
    ./browser.nix
    ./drone.nix
    ./gaming.nix
    ./hyprland.nix
    ./monitors.nix
    ./swaync.nix
    ./swayosd.nix
    ./waybar.nix
  ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        # Enable Wayland support on most Electron applications
        NIXOS_OZONE_WL = "1";

        # Enable newer FreeType features
        FREETYPE_PROPERTIES = "truetype:interpreter-version=40";

        BROWSER = config.dusk.defaults.browser;
        TERMINAL = terminal;

        QT_QPA_PLATFORM = "wayland";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        XDG_SESSION_TYPE = "wayland";
      };

      systemPackages = with pkgs; [
        brave
        easyeffects
        firefox
        gnome-calculator
        helvum
        imv
        obs-studio
        obsidian
        pinta
        telegram-desktop
        todoist-electron
        vlc
        wl-clipboard-rs

        # Fonts
        cantarell-fonts
        dejavu_fonts
        liberation_ttf
        noto-fonts
        source-code-pro
        source-sans
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

    home-manager.users.${config.dusk.username} =
      { lib, ... }:
      {
        catppuccin.kvantum.enable = false;

        dconf.settings."org/gnome/desktop/interface" = {
          gtk-theme = "Adwaita-dark";
          color-scheme = "prefer-dark";
        };

        home.activation.createNotesDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p "$HOME/Notes"
        '';

        gtk = {
          enable = true;

          font = {
            name = config.dusk.fonts.sans-serif;
            size = 11;
          };

          cursorTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };

          theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };

          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
        };

        qt = {
          enable = true;
          platformTheme.name = "adwaita-dark";
          style = {
            name = "adwaita-dark";
            package = pkgs.adwaita-qt;
          };
        };

        fonts.fontconfig.defaultFonts = {
          sansSerif = [ config.dusk.fonts.sans-serif ];
          serif = [ config.dusk.fonts.serif ];
          monospace = [ config.dusk.fonts.monospace ];
        };

        programs.obsidian = {
          enable = true;

          vaults.notes.target = "Notes";
        };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            # Open images with `imv`
            "image/png" = "imv.desktop";
            "image/jpeg" = "imv.desktop";
            "image/gif" = "imv.desktop";
            "image/webp" = "imv.desktop";
            "image/bmp" = "imv.desktop";
            "image/tiff" = "imv.desktop";

            # Open video files with VLC
            "video/mp4" = "vlc.desktop";
            "video/x-msvideo" = "vlc.desktop";
            "video/x-matroska" = "vlc.desktop";
            "video/x-flv" = "vlc.desktop";
            "video/x-ms-wmv" = "vlc.desktop";
            "video/mpeg" = "vlc.desktop";
            "video/ogg" = "vlc.desktop";
            "video/webm" = "vlc.desktop";
            "video/quicktime" = "vlc.desktop";
            "video/3gpp" = "vlc.desktop";
            "video/3gpp2" = "vlc.desktop";
            "video/x-ms-asf" = "vlc.desktop";
            "video/x-ogm+ogg" = "vlc.desktop";
            "video/x-theora+ogg" = "vlc.desktop";
            "application/ogg" = "vlc.desktop";
          };
        };
      };

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
