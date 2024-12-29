{
  config,
  lib,
  flavor,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optionals
    types
    ;
  cfg = config.dusk.terminal;
in
{
  imports =
    optionals (flavor == "nixos") [ { environment.systemPackages = with pkgs; [ ghostty ]; } ]
    ++ optionals (flavor == "darwin") [
      {
        homebrew = {
          enable = true;
          casks = [ "ghostty" ];
        };
      }
    ];

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
