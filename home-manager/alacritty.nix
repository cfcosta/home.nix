{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home.alacritty;
in {
  options = {
    dusk.home.alacritty = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata";
        };

        size = mkOption {
          type = types.int;
          default = 14;
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
          style: Regular
        bold:
          family: ${cfg.font.family}
          style: Bold
        italic:
          family: ${cfg.font.family}
          style: Medium Italic
        bold_italic:
          family: ${cfg.font.family}
          style: Bold Italic
        size: ${toString cfg.font.size}.0

      colors:
        primary:
          background: '#191a2a'
          foreground: '#c8d3f5'

        cursor:
          text:   '#7f85a3'
          cursor: '#808080'

        normal:
          black:   '#444a73'
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
