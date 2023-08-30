{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home.tmux;
in {
  options.dusk.home.tmux.enable = mkEnableOption "tmux";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ tmux tmuxp ];

    programs.tmux = {
      enable = true;
      escapeTime = 0;
      keyMode = "vi";
      terminal = "xterm-256color";
      plugins = with pkgs.tmuxPlugins; [({
        plugin = dracula;
        extraConfig = ''
          set -g @dracula-show-powerline true
          set -g @dracula-show-fahrenheit false
          set -g @dracula-show-battery false
        '';
      })];
      extraConfig = builtins.readFile ./tmux/config;
    };
  };
}
