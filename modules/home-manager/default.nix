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
    ./notes.nix
    ./tmux.nix
  ];

  options = {
    dusk.home = {
      name = mkOption { type = types.str; };
      email = mkOption { type = types.str; };
      username = mkOption { type = types.str; };
      accounts.github = mkOption { type = types.str; };

      shell = {
        environmentFile = mkOption {
          type = types.str;
          default = "${cfg.folders.home}/dusk-env.sh";
          description = ''
            A bash file that is loaded by the shell on each run.
            This is used to set secrets or credentials that we don't want on the repo.
          '';
        };
      };

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
      bashInteractive
      complete-alias
      eva
      fd
      git
      inconsolata
      libiconv
      luajit
      mosh
      ncdu
      neofetch
      nerdfonts
      python310Full
      ripgrep
      tree
      watchexec
      wget
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

    programs.bash = {
      enable = true;

      shellAliases = {
        ack = "rg";
        bc = "eva";
        cat = "bat --decorations=never";
        g = "git status --short";
        gc = "git commit";
        gca = "git commit -a";
        gco = "git checkout";
        gd = "git diff";
        gf = "git fetch -a";
        gl = "git log --graph";
        gp = "git push";
        gs = "git stash";
        gsp = "git stash pop";
        ls = "exa -l";
        vi = "nvim";
        vim = "nvim";
      };

      sessionVariables = {
        COLORTERM = "truecolor";
        EDITOR = "nvim";
        CDPATH = ".:${cfg.folders.code}";
      };

      historySize = 1000000;

      # Ignore common transaction commands and the aliases we've set.
      historyIgnore = [ "exit" "pwd" "reset" ]
        ++ (mapAttrsToList (key: _: key) config.programs.bash.shellAliases);

      shellOptions = [
        # Default options from home-manager
        "histappend"
        "checkwinsize"
        "extglob"
        "globstar"
        "checkjobs"

        # Custom Options
        "cdspell" # Correct transpositions and other minor details from 'cd DIR' command.
        "dotglob" # Include hidden files in glob (*).
        "extglob" # Extra-special pattern matching in the shell.
        "cmdhist" # Flatten multiple-line commands into the same history entry.
        "no_empty_cmd_completion" # Don't complete when I haven't typed anything.
        "shift_verbose" # Let me know if I shift stupidly.
      ];

      initExtra = ''
        . ${pkgs.complete-alias}/bin/complete_alias

        ${builtins.concatStringsSep "\n"
        (builtins.map (alias: "complete -F _complete_alias ${alias}")
          (builtins.attrNames config.programs.bash.shellAliases))}
      '';

      bashrcExtra = ''
        [ -f "${cfg.shell.environmentFile}" ] && source "${cfg.shell.environmentFile}"
      '';
    };

    home.stateVersion = "23.05";
  };
}
