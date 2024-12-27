{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;
  cfg = config.dusk.terminal;
in
{
  options.dusk.terminal.ghostty.theme = mkOption {
    description = "What theme to use on ghostty";
    type = types.str;
    default = "catppuccin-mocha";
  };

  config = mkIf (cfg.flavor == "ghostty") {
    home-manager.users.${config.dusk.username}.xdg.configFile."ghostty/config".text = ''
      theme = ${cfg.ghostty.theme}
      font-family = ${cfg.font-family}
      font-size = ${toString cfg.font-size}
    '';
  };
}
