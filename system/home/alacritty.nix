{ config, lib, ... }:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.alacritty;

  font = style: {
    inherit style;
    inherit (cfg.font) family;
  };
in
{
  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;

      settings = {
        env.TERM = "xterm-256color";

        font = {
          inherit (cfg.font) size;

          normal = font "Medium";
          bold = font "Bold";
          italic = font "Medium Italic";
          bold_italic = font "Bold Italic";
        };

        window = {
          blur = true;
          decorations = "None";
          decorations_theme_variant = "Dark";
          dynamic_padding = true;
          opacity = 0.8;
        };

        terminal.osc52 = "CopyPaste";
      };
    };
  };
}
