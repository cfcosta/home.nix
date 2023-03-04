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

    vscode = {
      enable = true;
      vimMode = true;
    };

    git = { enable = true; };

    lsp.enable = true;
  };
}
