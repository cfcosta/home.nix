{
  config,
  lib,
  pkgs,
  ...
}:
let
  font = style: {
    inherit style;
    inherit (config.dusk.alacritty.font) family;
  };
in
lib.optionalAttrs config.dusk.alacritty.enable {
  programs.alacritty = {
    enable = true;
    settings = {
      import = [ pkgs.alacritty-theme."${config.dusk.currentTheme.alacritty}" ];

      env.TERM = "xterm-256color";

      font = {
        inherit (config.dusk.alacritty.font) size;

        normal = font "Medium";
        bold = font "Bold";
        italic = font "Medium Italic";
        bold_italic = font "Bold Italic";
      };
    };
  };
}
