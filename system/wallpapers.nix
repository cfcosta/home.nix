{
  config,
  lib,
  pkgs,
  ...
}:
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

  config =
    let
      inherit (cfg.nixos.desktop) hyprland gnome;
    in
    {
      home-manager.users.${config.dusk.username} = _: {
        services.hyprpaper = {
          inherit (hyprland) enable;

          settings = {
            preload = map (pair: pair.value) all;
            wallpaper = map (pair: "${pair.name}, ${pair.value}") all;
          };
        };

        dconf.settings = mkIf gnome.enable (
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

        wayland.windowManager.hyprland.settings.exec-once = [ "${pkgs.hyprpaper}/bin/hyprpaper" ];
      };
    };
}
