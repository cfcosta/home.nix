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
  imports = [ ./drone.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnome-monitor-config ];

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

    xdg = {
      portal = {
        enable = true;

        extraPortals = with pkgs; [
          xdg-desktop-portal-gnome
          xdg-desktop-portal-gtk
          xdg-desktop-portal-wlr
        ];
      };
    };
  };
}
