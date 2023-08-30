{ config, lib, pkgs, ... }: {
  dusk.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    alacritty.enable = true;
    git.enable = true;
    mutt.enable = true;
    notes.enable = true;
    tmux.enable = true;
  };
}
