{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home;
in {
  imports = [
    ./alacritty.nix
    ./crypto.nix
    ./git.nix
    ./gnome.nix
    ./macos.nix
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

    programs.ssh.hashKnownHosts = true;

    home.packages = with pkgs; [
      eternal-terminal
      eva
      fd
      git
      inconsolata
      libiconv
      luajit
      neofetch
      nerdfonts
      python310Full
      ripgrep
      scc
      streamlink
      tokei
      tree
      watchexec
      wget
      yt-dlp
    ];

    programs.go.enable = true;
    programs.jq.enable = true;
    programs.gpg.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      config.global.load_dotenv = true;
    };

    programs.bat = {
      enable = true;
      config.theme = "Dracula";
    };

    programs.starship = {
      enable = true;
      enableBashIntegration = true;

      settings = {
        aws.style = "bold #ffb86c";
        cmd_duration.style = "bold #f1fa8c";
        directory.style = "bold #50fa7b";
        hostname.style = "bold #ff5555";
        git_branch.style = "bold #ff79c6";
        git_status.style = "bold #ff5555";
        username = {
          format = "[$user]($style) on ";
          style_user = "bold #bd93f9";
        };
        character = {
          success_symbol = "[❯](bold #50fa7b)";
          error_symbol = "[❯](bold #ff5555)";
        };
      };
    };

    programs.htop = {
      enable = true;
      package = pkgs.htop-vim;
    };

    programs.btop = {
      enable = true;

      settings = {
        color_theme = "dracula";
        true_color = true;
        vim_keys = true;
      };
    };

    home.stateVersion = "23.05";
  };
}
