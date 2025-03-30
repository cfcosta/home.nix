{
  config,
  flavor,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.dusk.terminal;

  window-theme = if (flavor == "nixos") then "ghostty" else "system";
in
{
  options.dusk.terminal = {
    default = mkOption {
      description = "The binary to the default terminal application";
      type = types.str;
      default = "${pkgs.ghostty}/bin/ghostty";
    };

    font-family = mkOption {
      type = types.str;
      default = "Inconsolata NerdFont";
    };

    font-size = mkOption {
      type = types.int;
      default = 14;
    };

    theme = mkOption {
      description = "What theme to use on ghostty";
      type = types.str;
      default = "catppuccin-mocha";
    };
  };

  config.home-manager.users.${config.dusk.username} = {
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
      theme = ${cfg.theme}
      font-family = ${cfg.font-family}
      font-size = ${toString cfg.font-size}
      background-opacity = 0.8
      background-blur-radius = 20
      window-theme = ${window-theme}
    '';
  };
}
