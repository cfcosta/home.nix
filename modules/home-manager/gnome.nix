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
    };
  };
}
