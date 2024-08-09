{ pkgs, ... }:
{
  alacritty = "gruvbox";
  bat = "gruvbox";
  btop = "gruvbox";
  delta-pager = "gruvbox";
  starship = {
    aws.style = "bold #d65d0e";
    cmd_duration.style = "bold #d79921";
    directory.style = "bold #98971a";
    hostname.style = "bold #cc241d";
    git_branch.style = "bold #b16286";
    git_status.style = "bold #cc241d";
    username = {
      format = "[$user]($style) on ";
      style_user = "bold #689d6a";
    };
    character = {
      success_symbol = "[❯](bold #98971a)";
      error_symbol = "[❯](bold #cc241d)";
    };
  };
  tmux = with pkgs.tmuxPlugins; {
    plugin = gruvbox;
    extraConfig = "set -g @tmux-gruvbox 'dark'";
  };
  zed = "Gruvbox Dark Hard";
}
