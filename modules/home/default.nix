{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.file) mkOutOfStoreSymlink;
  inherit (pkgs.dusk.inputs) neovim;
  inherit (pkgs.stdenv) isLinux;

  cfg = config.dusk;
in
{
  imports = [
    neovim.hmModule

    ../defaults

    ./shell
    ./tmux
    ./zed

    ./alacritty.nix
    ./git.nix
    ./media.nix
  ];

  config = {
    home = {
      inherit (cfg) username;
      homeDirectory = cfg.folders.home;

      file = mkIf isLinux {
        ".cache/nix-index".source = mkOutOfStoreSymlink "/var/db/nix-index";
      };

      packages = with pkgs; [
        (nerdfonts.override { fonts = [ "Inconsolata" ]; })

        b3sum
        git
        imagemagick
        inconsolata
        neofetch
        python312
      ];

      stateVersion = "24.11";
    };

    programs = {
      # Let home-manager manage itself
      home-manager.enable = true;
      ssh.hashKnownHosts = true;
      gpg.enable = true;
      nix-index.enable = true;
    };
  };
}
