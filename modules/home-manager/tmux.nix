{ config, pkgs, ... }: {
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
      '';
    })];
    extraConfig = builtins.readFile ./tmux/config;
  };
}
