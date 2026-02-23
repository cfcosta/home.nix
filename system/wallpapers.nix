{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) attrByPath filter mkIf;
  inherit (builtins)
    head
    pathExists
    tail
    toString
    ;

  wallpapers = pkgs.stdenvNoCC.mkDerivation {
    name = "dusk-wallpapers";
    src = ../wallpapers;
    installPhase = ''
      mkdir -p $out/share/wallpapers
      cp -r * $out/share/wallpapers/
    '';
  };

  cfg = config.dusk.system;
  wallpapersDir = toString ../wallpapers;

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

      configured = attrByPath [ name ] null cfg.wallpapers;
      sized = "${toString width}x${toString height}.jpg";
    in
    {
      inherit name;

      value = coalesce [
        (if configured != null && pathExists (toString configured) then configured else null)
        (if pathExists "${wallpapersDir}/${sized}" then "${wallpapers}/share/wallpapers/${sized}" else null)
        (
          if pathExists "${wallpapersDir}/default.jpg" then
            "${wallpapers}/share/wallpapers/default.jpg"
          else
            null
        )
      ];
    };

  # Don't check derivation outputs during eval: only validate source files and explicit overrides.
  exists = p: p.value != null;
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
      inherit (cfg.nixos.desktop) hyprland;
    in
    {
      home-manager.users.${config.dusk.username} = _: {
        home.packages = [ wallpapers ];

        services.hyprpaper = mkIf hyprland.enable {
          enable = true;

          settings = {
            preload = map (pair: pair.value) all;
            # Use hyprpaper's documented special-category form. Hyprland parsing is strict here.
            wallpaper = map (pair: {
              monitor = pair.name;
              path = pair.value;
              fit_mode = "cover";
            }) all;
          };
        };
      };
    };
}
