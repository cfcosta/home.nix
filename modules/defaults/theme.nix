{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    attrNames
    filter
    map
    readDir
    listToAttrs
    ;
  inherit (lib)
    mkOption
    types
    hasSuffix
    removeSuffix
    ;

  themes =
    let
      dir = ./themes;
      files = filter (hasSuffix ".nix") (attrNames (readDir dir));

      toAttr = n: {
        name = removeSuffix ".nix" n;
        value = import "${dir}/${n}" { inherit config lib pkgs; };
      };
    in
    listToAttrs (map toAttr files);

  current = themes."${config.dusk.theme}";
in
{
  options.dusk = {
  theme = mkOption {
    type = types.enum (attrNames themes);
    default = "gruvbox-dark";
  };
  zed.theme = mkOption {
    type = types.str;
    default = current.zed;
  };
  };

  config = {
    programs = {
      git.delta.options.theme = current.delta-pager;
      bat.config.theme = current.bat;
      btop.settings.color_theme = current.btop;
      starship.settings = current.starship;
      alacritty.settings.import = [ pkgs.alacritty-theme."${current.alacritty}" ];
      tmux.plugins = [ current.tmux ];
    };
  };
}
