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

  window-theme = if (flavor == "nixos") then "ghostty" else "system";
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

  config = mkIf (cfg.default == "ghostty") {
    home-manager.users.${config.dusk.username} = {
      programs.bash.initExtra =
        if (flavor == "nixos") then
          ''
            . ${pkgs.ghostty}/share/ghostty/shell-integration/bash/ghostty.bash
          ''
        else
          ''
            if [ -n "''${GHOSTTY_RESOURCES_DIR}" ]; then
              builtin source "''${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
            fi
          '';

      xdg.configFile."ghostty/config".text = ''
        theme = ${cfg.ghostty.theme}
        font-family = ${cfg.font-family}
        font-size = ${toString cfg.font-size}
        background-opacity = 0.8
        background-blur-radius = 20
        window-decoration = false
        window-theme = ${window-theme}
      '';
    };
  };
}
