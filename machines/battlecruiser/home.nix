{ config, lib, pkgs, ... }: {
  dusk.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    android.enable = true;
    alacritty.enable = true;
    git.enable = true;
    media.enable = true;
    mutt.enable = true;
    notes.enable = true;
    tmux.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" "us+intl" ];
    };
  };
}
