{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dusk.alacritty;
  font = style: {
    inherit style;
    family = cfg.font.family;
  };
in {
  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        import = [ pkgs.alacritty-theme."${cfg.theme}" ];

        env.TERM = "xterm-256color";

        font = {
          normal = font "Medium";
          bold = font "Bold";
          italic = font "Medium Italic";
          bold_italic = font "Bold Italic";
          size = cfg.font.size;
        };
      };
    };
  };
}
