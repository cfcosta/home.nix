{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.gnome;
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };

      systemPackages = with pkgs; [ gnome-monitor-config ];
    };

    home-manager.users.${config.dusk.username} = {
      gtk = {
        enable = true;

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        theme = {
          name = "palenight";
          package = pkgs.palenight-theme;
        };

        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };

        gtk3.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };

        gtk4.extraConfig = {
          Settings = ''
            gtk-application-prefer-dark-theme=1
          '';
        };
      };
    };

    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
        autoSuspend = false;
      };
    };
  };
}
