{ config, flavor, ... }:
let
  font = style: {
    inherit style;
    inherit (config.dusk.alacritty.font) family;
  };
in
{
  config = {
    programs.alacritty = {
      enable = flavor == "nixos" && config.dusk.system.nixos.desktop.enable;

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
