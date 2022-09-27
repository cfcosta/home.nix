{ config, lib, pkgs, ... }:
with lib; {
  devos.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    githubUser = "cfcosta";

    alacritty.enable = true;

    emacs = {
      enable = true;
      theme = "doom-nord-light";
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
