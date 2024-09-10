{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.dusk.home.tmux;
in
{
  options.dusk.home.tmux = {
    enable = mkEnableOption "tmux";
    showBattery = mkEnableOption "tmux show battery level";
  };

  config = mkIf cfg.enable {
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
    };

    home.file = mkIf pkgs.stdenv.isDarwin {
      ".terminfo/74/tmux-256color".source = mkIf pkgs.stdenv.isDarwin ./terminfo;
    };
  };
}
