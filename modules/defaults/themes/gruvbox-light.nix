{ pkgs, ... }:
{
  alacritty = "gruvbox_light";
  bat = "gruvbox-light";
  btop = "gruvbox_light";
  delta-pager = "gruvbox-light";
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
    extraConfig = "set -g @tmux-gruvbox 'light'";
  };
}
