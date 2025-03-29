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
    environment.systemPackages = with pkgs; [
      gnome-monitor-config
      gnomeExtensions.pop-shell
    ];

    home-manager.users.${config.dusk.username} =
      { lib, ... }:
      let
        inherit (lib.hm.gvariant) mkUint32;
      in
      {
        dconf = {
          enable = true;
          settings = {
            "org/gnome/desktop/interface".color-scheme = "prefer-dark";

            "org/gnome/shell" = {
              disable-user-extensions = false;
              enabled-extensions = with pkgs.gnomeExtensions; [
                pop-shell.extensionUuid
              ];
            };

            "org/gnome/shell/extensions/pop-shell" = {
              gap-inner = mkUint32 2;
              gap-outer = mkUint32 2;
            };
          };
        };

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

    services = {
      xserver = {
        enable = true;

        desktopManager.gnome.enable = true;
        displayManager.gdm = {
          enable = true;
          wayland = true;
          autoSuspend = false;
        };
      };

      udev.packages = with pkgs; [ gnome-settings-daemon ];
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
