{ lib, config, ... }:
let
  inherit (lib)
    attrByPath
    filter
    listToAttrs
    mkIf
    ;
  inherit (builtins) pathExists toString;
  cfg = config.dusk.system;

  getWallpaper =
    monitor:
    let
      inherit (monitor) name;
      inherit (monitor.resolution) width height;

      coalesce = a: b: if a != null then a else b;
      user = attrByPath [ name ] null cfg.wallpapers;
      default = ../../assets/wallpapers + "/${toString width}x${toString height}.jpg";
      value = coalesce user default;
    in
    {
      inherit name;
      value = if value == null then null else toString value;
    };

  exists = p: (p.value != null) && (pathExists p.value);
  all = filter exists (map getWallpaper cfg.monitors);
  getPath = m: (getWallpaper m).value;
in
{
  options.dusk.system.wallpapers =
    with lib;
    mkOption {
      type = types.attrsOf types.path;
      description = "Override default wallpapers";
      default = { };
    };

  config = mkIf (cfg.nixos.desktop.enable && cfg.monitors != [ ]) {
    home-manager.users.${config.dusk.username} = {
      services.hyprpaper = mkIf cfg.nixos.desktop.hyprland.enable {
        settings = {
          preload = map (pair: pair.value) all;
          wallpaper = map (pair: "${pair.name}, ${pair.value}") all;
        };
      };

      dconf.settings = mkIf cfg.nixos.desktop.gnome.enable (
        listToAttrs (
          map (monitor: {
            name = "org/gnome/desktop/background/picture-options-${monitor.name}";
            value = {
              picture-uri = "file://${getPath monitor}";
              picture-uri-dark = "file://${getPath monitor}";
            };
          }) all
        )
      );
    };
  };
}
