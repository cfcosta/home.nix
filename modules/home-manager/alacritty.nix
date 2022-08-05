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
          default = "16";
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

      # Moonlight theme
      colors:
        primary:
          background: '#212337'
          foreground: '#b4c2f0'
        cursor:
          text:   '#7f85a3'
          cursor: '#808080'
        normal:
          black:   '#191a2a'
          red:     '#ff5370'
          green:   '#4fd6be'
          yellow:  '#ffc777'
          blue:    '#3e68d7'
          magenta: '#fc7b7b'
          cyan:    '#86e1fc'
          white:   '#d0d0d0'
        bright:
          black:   '#828bb8'
          red:     '#ff98a4'
          green:   '#c3e88d'
          yellow:  '#ffc777'
          blue:    '#82aaff'
          magenta: '#ff966c'
          cyan:    '#b4f9f8'
          white:   '#5f8787'
        indexed_colors: []
    '';
  };
}
