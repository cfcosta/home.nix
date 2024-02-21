{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk;
in {
  imports = [
    ./shell
    ./tmux

    ./android.nix
    ./alacritty.nix
    ./git.nix
    ./gnome.nix
    ./macos.nix
    ./media.nix
  ];

  config = rec {
    home.username = cfg.user.username;
    home.homeDirectory = cfg.user.folders.home;

    home.packages = with pkgs; [
      git
      imagemagick
      inconsolata
      neofetch
      nerdfonts
      python311
    ];

    # Let home-manager manage itself
    programs.home-manager.enable = true;

    programs.ssh.hashKnownHosts = true;
    programs.gpg.enable = true;
    programs.nix-index.enable = true;

    home.file = mkIf pkgs.stdenv.isLinux {
      ".cache/nix-index".source =
        config.lib.file.mkOutOfStoreSymlink "/var/db/nix-index";
    };

    home.stateVersion = "23.11";
  };
}
