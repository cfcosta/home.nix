{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home;
in {
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

  config = rec {
    home.packages = with pkgs; [
      bashInteractive
      complete-alias
      eternal-terminal
      eva
      fd
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
      streamlink
      tokei
      tree
      unixtools.watch
      watchexec
      wget
      whiz
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
      };

      historySize = 1000000;

      # Ignore common transaction commands and the aliases we've set.
      historyIgnore = [ "exit" "pwd" "reset" "fg" "jobs" ]
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
        ${if pkgs.stdenv.isDarwin then (builtins.readFile ./macos.sh) else ""}

        # Man-pages coloring with Dracula theme
        export LESS_TERMCAP_mb=$'\e[1;31m'      # begin bold
        export LESS_TERMCAP_md=$'\e[1;34m'      # begin blink
        export LESS_TERMCAP_so=$'\e[01;45;37m'  # begin reverse video
        export LESS_TERMCAP_us=$'\e[01;36m'     # begin underline
        export LESS_TERMCAP_me=$'\e[0m'         # reset bold/blink
        export LESS_TERMCAP_se=$'\e[0m'         # reset reverse video
        export LESS_TERMCAP_ue=$'\e[0m'         # reset underline

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

        history_filter = [ "^ls" "^cd" "^cat" "^fg" "^jobs" ]
          ++ (builtins.map (alias: ''"^${alias}"'')
            (builtins.attrNames config.programs.bash.shellAliases));
      };
    };

    programs.bat = {
      enable = true;
      config.theme = "Dracula";
    };

    programs.btop = {
      enable = true;

      settings = {
        color_theme = "dracula";
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
        blocks = [ "permission" "user" "size" "git" "name" ];
        icons.theme = "fancy";
        ignore-globs = [ ".direnv" ".git" ".hg" ".jj" ];
        permission = "rwx";
      };
    };

    programs.readline = {
      enable = true;

      extraConfig = ''
        # If there's more than one completion for an input, list all options immediately 
        # instead of waiting for a second input.
        set show-all-if-ambiguous on
      '';
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

    home.file.".config/lsd/colors.yaml".text =
      builtins.readFile ./lsd/colors.yaml;

    xdg.configFile."pgcli/config".text = builtins.readFile ./pgcli.conf;
  };
}
