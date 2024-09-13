{ config, ... }:
let
  font = style: {
    inherit style;
    inherit (config.dusk.alacritty.font) family;
  };
in
{
  config = {
    programs.alacritty = {
      enable = true;

      settings = {
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

  };
}
