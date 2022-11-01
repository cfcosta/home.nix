{ config, lib, pkgs, ... }:
with lib; {
  devos.home = {
    name = "DevOS Custom User";
    username = "devos";
    email = "devos@example.com";
    githubUser = "";

    firefox.enable = true;

    alacritty = {
      enable = true;
      font.family = "Inconsolata";
    };

    cloud.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" ];
    };

    emacs = {
      enable = true;
      theme = "doom-moonlight";

      fonts.fixed = {
        family = "Inconsolata";
        size = "18";
      };

      fonts.variable = {
        family = "Inconsolata";
        size = "18";
      };
    };

    vscode = {
      enable = true;
      vimMode = true;
    };

    git = { enable = true; };

    runtimes = { rust.enable = true; };
  };
}
