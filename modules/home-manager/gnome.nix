{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home;
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
    };
  };

  config = mkIf cfg.gnome.enable {
    home.packages = with pkgs; [ adw-gtk3 ];

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
        switch-input-source = [ "<Super>Tab" ];
        switch-input-source-backward = [ "<Shift><Super>Tab" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        toggle-fullscreen = [ "<Super>f" ];
      };
    };
  };
}
