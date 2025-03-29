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
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
              gtk-theme = "palenight";
            };

            "org/gnome/desktop/wm/keybindings" = {
              close = [ "<Super>q" ];

              maximize = [ ];
              minimize = [ ];

              move-to-monitor-down = [ ];
              move-to-monitor-left = [ ];
              move-to-monitor-right = [ ];
              move-to-monitor-up = [ ];

              move-to-workspace-1 = [ "<Shift><Super>1" ];
              move-to-workspace-2 = [ "<Shift><Super>2" ];
              move-to-workspace-3 = [ "<Shift><Super>3" ];
              move-to-workspace-4 = [ "<Shift><Super>4" ];
              move-to-workspace-5 = [ "<Shift><Super>5" ];
              move-to-workspace-6 = [ "<Shift><Super>6" ];
              move-to-workspace-7 = [ "<Shift><Super>7" ];
              move-to-workspace-8 = [ "<Shift><Super>8" ];
              move-to-workspace-9 = [ "<Shift><Super>9" ];

              move-to-workspace-down = [ ];
              move-to-workspace-up = [ ];

              switch-to-workspace-1 = [ "<Super>1" ];
              switch-to-workspace-2 = [ "<Super>2" ];
              switch-to-workspace-3 = [ "<Super>3" ];
              switch-to-workspace-4 = [ "<Super>4" ];
              switch-to-workspace-5 = [ "<Super>5" ];
              switch-to-workspace-6 = [ "<Super>6" ];
              switch-to-workspace-7 = [ "<Super>7" ];
              switch-to-workspace-8 = [ "<Super>8" ];
              switch-to-workspace-9 = [ "<Super>9" ];

              switch-to-workspace-down = [ ];
              switch-to-workspace-left = [ ];
              switch-to-workspace-right = [ ];
              switch-to-workspace-up = [ ];

              toggle-maximized = [ ];
              unmaximize = [ ];
            };

            "org/gnome/shell" = {
              disable-user-extensions = false;
              enabled-extensions = with pkgs.gnomeExtensions; [ pop-shell.extensionUuid ];
              favorite-apps = [ ];
            };

            "org/gnome/shell/extensions/pop-shell" = {
              gap-inner = mkUint32 4;
              gap-outer = mkUint32 4;
            };
          };
        };

        gtk = {
          enable = true;

          cursorTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };

          theme = {
            name = "palenight";
            package = pkgs.palenight-theme;
          };

          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
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
