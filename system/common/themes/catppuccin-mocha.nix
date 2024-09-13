{ pkgs, ... }:
let
  inherit (builtins) fromTOML readFile;
in
{
  alacritty = "catppuccin_mocha";
  bat = "catppuccin-mocha";
  btop = "catppuccin-mocha";
  delta-pager = "catppuccin-mocha";
  pgcli = "monokai"; # Fix: add custom theme
  starship = fromTOML (readFile ./starship/catppuccin-mocha.toml);
  tmux = {
    plugin = pkgs.tmuxPlugins.catppuccin;
    extraConfig = ''
      set -g @catppuccin_flavor 'mocha'
    '';
  };
  zed = "Catppuccin Mocha";
}
