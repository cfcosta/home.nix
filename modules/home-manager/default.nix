{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home;
in {
  imports = [
    ./alacritty.nix
    ./crypto.nix
    ./git.nix
    ./gnome.nix
    ./media.nix
    ./mutt.nix
    ./notes.nix
    ./shell.nix
    ./tmux.nix
  ];

  options = {
    dusk.home = {
      name = mkOption { type = types.str; };
      email = mkOption { type = types.str; };
      username = mkOption { type = types.str; };
      accounts.github = mkOption { type = types.str; };

      folders = {
        code = mkOption {
          type = types.str;
          default = "${cfg.folders.home}/Code";
          description = "Where you host your working projects";
        };

        home = mkOption {
          type = types.str;
          default = if pkgs.stdenv.isLinux then
            "/home/${cfg.username}"
          else
            "/Users/${cfg.username}";
          description = "Your home folder";
        };
      };
    };
  };

  config = rec {
    home.username = cfg.username;
    home.homeDirectory = cfg.folders.home;

    # Let home-manager manage itself
    programs.home-manager.enable = true;

    home.sessionVariables.EDITOR = "nvim";

    home.packages = with pkgs; [
      eva
      fd
      git
      inconsolata
      libiconv
      luajit
      mosh
      neofetch
      nerdfonts
      python310Full
      ripgrep
      scc
      tokei
      tree
      watchexec
      wget
      yt-dlp
    ];

    programs.bat.enable = true;
    programs.bottom.enable = true;
    programs.btop.enable = true;
    programs.exa.enable = true;
    programs.go.enable = true;
    programs.jq.enable = true;
    programs.starship.enable = true;
    programs.gpg.enable = true;
    programs.direnv.enable = true;

    programs.htop = {
      enable = true;
      package = pkgs.htop-vim;
    };

    home.stateVersion = "23.05";
  };
}
