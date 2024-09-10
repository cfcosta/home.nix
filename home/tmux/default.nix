{
  pkgs,
  config,
  ...
}:
{
  config = {
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
      plugins = [ config.dusk.theme.settings.tmux ];
    };
  };
}
