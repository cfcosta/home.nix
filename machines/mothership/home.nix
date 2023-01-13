{ config, lib, pkgs, ... }: {
  devos.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    githubUser = "cfcosta";

    firefox = {
      enable = true;
      gnomeTheme = false;
    };

    alacritty = {
      enable = true;
      font.family = "Inconsolata";
    };

    cloud.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" "us+intl" ];
    };

    emacs = {
      enable = true;
      theme = "doom-moonlight";
      wayland = false;
      graphical = true;

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

    lsp.enable = true;
    runtimes.rust.enable = true;
  };
}
