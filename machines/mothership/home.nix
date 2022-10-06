{ config, lib, pkgs, ... }:
let inherit (lib.hm.gvariant) mkTuple;
in with lib; {
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
  };

  dconf.settings."org/gnome/desktop/input-sources" = {
    sources = [ (mkTuple [ "xkb" "us" ]) (mkTuple [ "xkb" "us+intl" ]) ];
  };
}
