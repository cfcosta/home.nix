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
      theme = "doom-moonlight";

      fonts.fixed = {
        family = "Inconsolata";
        size = "24";
      };

      fonts.variable = {
        family = "Inconsolata";
        size = "24";
      };
    };

    vscode = {
      enable = true;
      vimMode = true;
    };

    git = { enable = true; };
  };
}
