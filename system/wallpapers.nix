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
  inherit (builtins)
    head
    pathExists
    tail
    toString
    ;

  wallpapers = pkgs.stdenvNoCC.mkDerivation {
    name = "dusk-wallpapers";
    src = ../assets/wallpapers;
    installPhase = ''
      mkdir -p $out/share/wallpapers
      cp -r * $out/share/wallpapers/
    '';
  };

  cfg = config.dusk.system;

  getWallpaper =
    monitor:
    let
      inherit (monitor) name;
      inherit (monitor.resolution) width height;

      coalesce =
        list:
        let
          go =
            xs:
            if xs == [ ] then
              null
            else if head xs != null then
              head xs
            else
              go (tail xs);
        in
        go list;
    in
    {
      inherit name;

      value = coalesce [
        (attrByPath [ name ] null cfg.wallpapers)
        "${wallpapers}/share/wallpapers/${toString width}x${toString height}.jpg"
        "${wallpapers}/share/wallpapers/default.jpg"
      ];
    };

  exists = p: (p.value != null) && (pathExists p.value);
  all = filter exists (map getWallpaper cfg.monitors);
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
        home.packages = [ wallpapers ];

        services.hyprpaper = mkIf hyprland.enable {
          enable = true;

          settings = {
            preload = map (pair: pair.value) all;
            wallpaper = map (pair: "${pair.name}, ${pair.value}") all;
          };
        };

        dconf.settings = mkIf gnome.enable (
          listToAttrs (
            map (
              { name, value }:
              {
                name = "org/gnome/desktop/background/picture-options-${name}";
                value = {
                  picture-uri = "file://${value}";
                  picture-uri-dark = "file://${value}";
                };
              }
            ) all
          )
        );
      };
    };
}
