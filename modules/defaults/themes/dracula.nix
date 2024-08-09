{ pkgs, ... }:
{
  alacritty = "dracula";
  bat = "Dracula";
  btop = "dracula";
  delta-pager = "Dracula";
  starship = {
    aws.style = "bold #ffb86c";
    cmd_duration.style = "bold #f1fa8c";
    directory.style = "bold #50fa7b";
    hostname.style = "bold #ff5555";
    git_branch.style = "bold #ff79c6";
    git_status.style = "bold #ff5555";
    username = {
      format = "[$user]($style) on ";
      style_user = "bold #bd93f9";
    };
    character = {
      success_symbol = "[❯](bold #50fa7b)";
      error_symbol = "[❯](bold #ff5555)";
    };
  };
  tmux = with pkgs.tmuxPlugins; {
    plugin = dracula;
    extraConfig = ''
      set -g @dracula-show-powerline true
      set -g @dracula-show-fahrenheit false
      set -g @dracula-show-location false
      set -g @dracula-show-battery ${if config.dusk.home.tmux.showBattery then "true" else "false"}
    '';
  };
  zed = "Dracula";
}
