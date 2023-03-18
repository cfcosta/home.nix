{ config, lib, pkgs, ... }: {
  devos.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    alacritty.enable = true;
    cloud.enable = true;
    git.enable = true;
    lsp.enable = true;
    notes.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" "us+intl" ];
    };
  };
}
