{ config, ... }:
let
  cfg = config.dusk.terminal;

  font = style: {
    inherit style;
    family = cfg.font-family;
  };
in
{
  config.home-manager.users.${config.dusk.username} = {
    programs.alacritty = {
      enable = cfg.default == "alacritty";

      settings = {
        env.TERM = "xterm-256color";

        font = {
          size = cfg.font-size;

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
