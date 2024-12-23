{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) readFile;
  inherit (lib) mkEnableOption;
in
{
  options.dusk.shell.tmux.showBattery = mkEnableOption "Show battery level";

  config = {
    environment.systemPackages = with pkgs; [ tmux ];

    home-manager.users.${config.dusk.username} = _: {
      programs.tmux = {
        enable = true;

        escapeTime = 0;
        keyMode = "vi";
        terminal = "xterm-256color";
        extraConfig = readFile ./config;
      };
    };
  };
}
