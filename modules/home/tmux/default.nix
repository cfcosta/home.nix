{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home.tmux;
in {
  options.dusk.home.tmux = {
    enable = mkEnableOption "tmux";
    showBattery = mkEnableOption "tmux show battery level";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ tmux tmuxp ];

    programs.tmux = {
      enable = true;
      escapeTime = 0;
      keyMode = "vi";
      terminal = "tmux-256color";

      plugins = with pkgs.tmuxPlugins; [({
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-show-powerline true
          set -g @dracula-show-fahrenheit false
          set -g @dracula-show-location false
          set -g @dracula-show-battery ${
            if cfg.showBattery then "true" else "false"
          }
        '';
      })];

      extraConfig = builtins.readFile ./config;
    };

    home.file = mkIf (pkgs.stdenv.isDarwin) {
      ".terminfo/74/tmux-256color".source =
        mkIf pkgs.stdenv.isDarwin ./terminfo;
    };
  };
}
