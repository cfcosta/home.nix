{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv) isDarwin;
in
mkIf config.dusk.tmux.enable {
  home.packages = with pkgs; [
    tmux
    tmuxp
  ];

  programs.tmux = {
    enable = true;
    escapeTime = 0;
    keyMode = "vi";
    terminal = "tmux-256color";
    extraConfig = builtins.readFile ./config;
    plugins = [ config.dusk.currentTheme.tmux ];
  };

  home.file = mkIf isDarwin {
    ".terminfo/74/tmux-256color".source = ./terminfo;
  };
}
