{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.devos.home;
  inherit (lib.hm.gvariant) mkTuple;
in {
  options = {
    devos.home.gnome = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      darkTheme = mkOption {
        type = types.bool;
        default = false;
      };

      keymaps = mkOption {
        type = types.listOf types.string;
        default = [ "us" ];
      };
    };
  };

  config = mkIf cfg.gnome.enable {
    home.packages = with pkgs; [ adw-gtk3 ];

    home.sessionVariables = {
      GTK_IM_MODULE = "cedilla";
      QT_IM_MODULE = "cedilla";
    };

    qt.enable = true;
    qt.platformTheme = "gnome";
    qt.style.package = pkgs.adwaita-qt;
    qt.style.name = if cfg.gnome.darkTheme then "adwaita-dark" else "adwaita";

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme =
          if cfg.gnome.darkTheme then "prefer-dark" else "prefer-light";
        gtk-theme = if cfg.gnome.darkTheme then "adw-gtk3-dark" else "adw-gtk3";

        clock-show-weekday = true;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        move-to-workspace-1 = [ "<Shift><Super>exclam" ];
        move-to-workspace-2 = [ "<Shift><Super>at" ];
        move-to-workspace-3 = [ "<Shift><Super>numbersign" ];
        move-to-workspace-4 = [ "<Shift><Super>dollar" ];
        move-to-workspace-5 = [ "<Shift><Super>percent" ];
        move-to-workspace-6 = [ "<Shift><Super>dead_circumflex" ];
        switch-input-source = [ "<Super>Tab" ];
        switch-input-source-backward = [ "<Shift><Super>Tab" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        toggle-fullscreen = [ "<Super>f" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        # Lock Screen
        screensaver = [ "Pause" ];

        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
        {
          binding = "<Super>b";
          command = "firefox";
          name = "Launch Browser";
        };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" =
        {
          binding = "<Super>Return";
          command = "alacritty";
          name = "Launch Terminal";
        };

      "org/gnome/desktop/input-sources" = {
        sources = map (x: (mkTuple [ "xkb" x ])) cfg.gnome.keymaps;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions =
          [ "blur-my-shell@aunetx" "dash-to-dock@micxgx.gmail.com" ];
        disabled-extensions = [ ];

        # Disable gnome tour when starting for the first time by setting a
        # really high version.
        welcome-dialog-last-shown-version = "4294967295";
      };

      # Make dash-to-dock look nice using blur-my-shell
      "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
        blur = true;
        customize = false;
        override-background = true;
        style-dash-to-dock = 0;
        unblur-in-overview = false;
      };
    };
  };
}
