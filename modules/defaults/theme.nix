{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) attrNames filter map readDir listToAttrs;
  inherit (lib) mkOption types hasSuffix removeSuffix;

  themes =
    let
      dir = ./themes;
      files = filter (hasSuffix ".nix") (attrNames (readDir dir));

      toAttr = n: {
        name = removeSuffix ".nix" n;
        value = import "${dir}/${n}";
      };
    in
    listToAttrs (map toAttr files);

  current = themes."${config.dusk.theme}";
in
{
  options.dusk.theme = mkOption {
    type = types.enum (attrNames themes);
    default = "gruvbox-light";
  };

  config = {
    programs.git.delta.options.theme = current.delta-pager;
    programs.bat.config.theme = current.bat;
    programs.btop.settings.color_theme = current.btop;
    programs.starship.settings = current.starship;
    programs.alacritty.settings.import = [ pkgs.alacritty-theme."${current.alacritty}" ];
  };
}
