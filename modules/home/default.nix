{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dusk.home;
in
{
  imports = [
    ../defaults

    ./shell
    ./tmux

    ./alacritty.nix
    ./git.nix
    ./gnome.nix
    ./media.nix
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
          default = if pkgs.stdenv.isLinux then "/home/${cfg.username}" else "/Users/${cfg.username}";
          description = "Your home folder";
        };
      };
    };
  };

  config = {
    home.username = cfg.username;
    home.homeDirectory = cfg.folders.home;

    home.packages = with pkgs; [
      (nerdfonts.override { fonts = [ "Inconsolata" ]; })

      b3sum
      git
      imagemagick
      inconsolata
      neofetch
      python312
    ];

    # Let home-manager manage itself
    programs.home-manager.enable = true;

    programs.ssh.hashKnownHosts = true;
    programs.gpg.enable = true;
    programs.nix-index.enable = true;

    home.file = mkIf pkgs.stdenv.isLinux {
      ".cache/nix-index".source = config.lib.file.mkOutOfStoreSymlink "/var/db/nix-index";
    };

    home.stateVersion = "24.05";
  };
}
