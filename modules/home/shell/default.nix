{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types mapAttrsToList;
  cfg = config.dusk.home;
in
{
  options = {
    dusk.home.shell = {
      environmentFile = mkOption {
        type = types.str;
        default = "${cfg.folders.home}/dusk-env.sh";
        description = ''
          A bash file that is loaded by the shell on each run.
          This is used to set secrets or credentials that we don't want on the repo.
        '';
      };
    };
  };

  config = {
    home.packages = with pkgs; [
      bashInteractive
      complete-alias
      eva
      fd
      fdupes
      gist
      git
      glow
      lsof
      ncdu_2
      neofetch
      pgcli
      ranger
      ripgrep
      scc
      tokei
      tree
      unixtools.watch
      watchexec
      wget
    ];

    programs.jq.enable = true;
    programs.zoxide.enable = true;

    programs.bash = {
      enable = true;
      enableCompletion = true;

      shellAliases = {
        ack = "rg";
        bc = "eva";
        cat = "bat --decorations=never";
        g = "git status --short";
        gc = "git commit";
        gca = "git commit -a";
        gco = "git checkout";
        gcp = "git cherry-pick";
        gd = "git diff";
        gf = "git fetch -a --tags";
        gl = "git log --graph";
        gp = "git push";
        gs = "git stash";
        gsp = "git stash pop";
        htop = "btop";
        jd = "jj diff";
        jl = "jj log";
        ll = "lsd -l -A";
        ls = "lsd -l";
        vi = "nvim";
        vim = "nvim";
      };

      sessionVariables = {
        COLORTERM = "truecolor";
        EDITOR = "nvim";
        CDPATH = ".:${cfg.folders.code}";
        MANPAGER = "${pkgs.less}/bin/less -s -M +Gg";
        MAN_PAGER = "sh -c 'col -bx | bat -l man -p'";
      };

      historySize = 1000000;

      # Ignore common transaction commands and the aliases we've set.
      historyIgnore = [
        "exit"
        "pwd"
        "reset"
        "fg"
        "jobs"
      ] ++ (mapAttrsToList (key: _: key) config.programs.bash.shellAliases);

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

        ${builtins.concatStringsSep "\n" (
          builtins.map (alias: "complete -F _complete_alias ${alias}") (
            builtins.attrNames config.programs.bash.shellAliases
          )
        )}
      '';

      bashrcExtra = ''
        ${if pkgs.stdenv.isDarwin then (builtins.readFile ./macos.sh) else ""}

        [ -f "${cfg.shell.environmentFile}" ] && source "${cfg.shell.environmentFile}"
      '';
    };

    # Make ctrl-r much more powerful
    # https://github.com/ellie/atuin
    programs.atuin = {
      enable = true;
      flags = [ "--disable-up-arrow" ];
      settings = {
        auto_sync = false;
        update_check = false;
        style = "compact";
        show_help = false;

        history_filter = [
          "^ls"
          "^cd"
          "^cat"
          "^fg"
          "^jobs"
        ] ++ (builtins.map (alias: ''"^${alias}"'') (builtins.attrNames config.programs.bash.shellAliases));
      };
    };

    programs.bat.enable = true;

    programs.btop = {
      enable = true;

      settings = {
        true_color = true;
        vim_keys = true;
      };
    };

    programs.direnv = {
      enable = true;

      nix-direnv.enable = true;

      config.global = {
        load_dotenv = true;
        hide_env_diff = true;
        strict_env = true;
      };
    };

    programs.lsd = {
      enable = true;

      settings = {
        blocks = [
          "permission"
          "user"
          "size"
          "git"
          "name"
        ];
        icons.theme = "fancy";
        ignore-globs = [
          ".direnv"
          ".git"
          ".hg"
          ".jj"
          "target"
        ];
        permission = "rwx";
      };
    };

    programs.readline = {
      enable = true;

      extraConfig = ''
        # If there's more than one completion for an input, list all options immediately
        # instead of waiting for a second input.
        set show-all-if-ambiguous on

        # Use arrow keys to search history from cursor position
        "\e[A":history-search-backward
        "\e[B":history-search-forward

        # Do the same for Ctrl-P and Ctrl-N
        "\C-p":history-search-backward
        "\C-n":history-search-forward
      '';
    };

    programs.starship = {
      enable = true;
      enableBashIntegration = true;
    };

    xdg.configFile."pgcli/config".text = builtins.readFile ./pgcli.conf;
  };
}
