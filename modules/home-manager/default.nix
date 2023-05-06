{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home;
in {
  imports = [
    ./alacritty.nix
    ./cloud.nix
    ./git.nix
    ./gnome.nix
    ./lsp.nix
    ./media.nix
    ./notes.nix
    ./tmux.nix
  ];

  options = {
    devos.home = {
      name = mkOption { type = types.str; };
      email = mkOption { type = types.str; };
      username = mkOption { type = types.str; };
      accounts.github = mkOption { type = types.str; };

      folders = {
        code = mkOption {
          type = types.str;
          default = "~/Code";
        };

        home = mkOption {
          type = types.str;
          default = if pkgs.stdenv.isLinux then
            "/home/${cfg.username}"
          else
            "/Users/${cfg.username}";
        };
      };
    };
  };

  config = {
    home.username = cfg.username;
    home.homeDirectory = cfg.folders.home;

    # Let home-manager manage itself
    programs.home-manager.enable = true;

    home.sessionVariables = {
      COLORTERM = "truecolor";
      EDITOR = "nvim";
      CDPATH = ".:${cfg.folders.code}";
    };

    home.packages = with pkgs; [
      bash
      eva
      fd
      git
      inconsolata
      ncdu
      neofetch
      nerdfonts
      python310Full
      ripgrep
      tree
      watchexec
      wget
    ];

    programs.devos.neovim.enable = true;

    programs.bat.enable = true;
    programs.bottom.enable = true;
    programs.exa.enable = true;
    programs.go.enable = true;
    programs.htop.enable = true;
    programs.jq.enable = true;
    programs.starship.enable = true;
    programs.gpg.enable = true;
    programs.direnv.enable = true;

    programs.bash.enable = true;
    programs.bash.shellAliases = {
      ack = "rg";
      cat = "bat --decorations=never";
      g = "git status --short";
      gc = "git commit";
      gca = "git commit -a";
      gp = "git push";
      gco = "git checkout";
      gf = "git fetch -a";
      gl = "git log --graph";
      gs = "git stash";
      gsp = "git stash pop";
      gd = "git diff";
      ls = "exa -l";
      vim = "nvim";
      vi = "nvim";
    };

    home.stateVersion = "22.11";
  };
}
