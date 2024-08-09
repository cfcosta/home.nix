{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.dusk.home.alacritty;

  font = style: {
    inherit style;
    family = cfg.font.family;
  };
in
{
  options = {
    dusk.home.alacritty = {
      enable = mkEnableOption "alacritty";

      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata";
        };

        size = mkOption {
          type = types.float;
          default = 14.0;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      settings = {
        import = [ pkgs.alacritty-theme."${config.dusk.theme.alacritty}" ];

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
