{ config, lib, pkgs, ... }: {
  devos.home = {
    username = "cfcosta";
    email = "me@cfcosta.com";

    alacritty.enable = true;
    emacs.enable = true;
  };

  programs.git = {
    enable = true;

    userName = "Cainã Costa";
    userEmail = "me@cfcosta.com";

    signing = {
      key = null;
      signByDefault = false;
    };

    extraConfig = {
      init.defaultBranch = "main";
      github.user = "cfcosta";
    };
  };
}
