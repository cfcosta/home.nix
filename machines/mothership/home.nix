{ config, lib, pkgs, ... }:
with lib; {
  devos.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    githubUser = "cfcosta";

    alacritty.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
    };

    emacs = {
      enable = true;
      theme = "doom-vibrant";
      fonts.fixed.family = "Inconsolata";
      fonts.variable.family = "Inconsolata";
    };

    vscode = {
      enable = true;
      vimMode = true;
    };

    git = { enable = true; };
  };
}
