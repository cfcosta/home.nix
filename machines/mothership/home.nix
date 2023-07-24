{ config, lib, pkgs, ... }: {
  dusk.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    alacritty.enable = true;
    git.enable = true;
    media.enable = true;
    notes.enable = true;
    crypto.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" "us+intl" ];
    };
  };
}
