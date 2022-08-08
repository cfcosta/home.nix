{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home.alacritty;
in {
  options = {
    devos.home.alacritty = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      font = {
        family = mkOption {
          type = types.str;
          default = "FuraCode Nerd Font";
        };

        weight = mkOption {
          type = types.str;
          default = "medium";
        };

        size = mkOption {
          type = types.str;
          default = "14";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.file.".config/alacritty/alacritty.yml".text = with personal.options; ''
      env:
        TERM: xterm-256color
      font:
        normal:
          family: ${cfg.font.family}
          style: Medium
        bold:
          family: ${cfg.font.family}
          style: Bold
        italic:
          family: ${cfg.font.family}
          style: Medium Italic
        bold_italic:
          family: ${cfg.font.family}
          style: Bold Italic
        size: ${cfg.font.size}.0

      # Colors (IR Black)
      colors:
        # Default colors
        primary:
          background: '#000000'
          foreground: '#eeeeee'

        cursor:
          text: '#ffffff'
          cursor: '#ffffff'

        # Normal colors
        normal:
          black:   '#4e4e4e'
          red:     '#ff6c60'
          green:   '#a8ff60'
          yellow:  '#ffffb6'
          blue:    '#96cbfe'
          magenta: '#ff73fd'
          cyan:    '#c6c5fe'
          white:   '#eeeeee'

        # Bright colors
        bright:
          black:   '#7c7c7c'
          red:     '#ffb6b0'
          green:   '#ceffab'
          yellow:  '#ffffcb'
          blue:    '#b5dcfe'
          magenta: '#ff9cfe'
          cyan:    '#dfdffe'
          white:   '#ffffff'

        indexed_colors: []
    '';
  };
}
