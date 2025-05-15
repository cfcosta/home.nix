{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (builtins) attrNames concatStringsSep map;
  inherit (lib) mapAttrsToList mkForce;

  completeAliases = map (alias: "complete -F _complete_alias ${alias}") (
    attrNames config.programs.bash.shellAliases
  );
in
{
  imports = [
    inputs.agenix.homeManagerModules.default
    inputs.catppuccin.homeModules.catppuccin

    ./git.nix
    ./jujutsu.nix
    ./zed
  ];

  config = {
    catppuccin = {
      enable = true;
      nvim.enable = false;
    };

    fonts.fontconfig.enable = true;

    home = {
      inherit (config.dusk) username;

      file.".aiderignore".text = ''
        *.age
        *.lock
        /.git
        /.github
        /.gitignore
        LICENSE
        LICENSE*
      '';

      homeDirectory = mkForce config.dusk.folders.home;

      stateVersion = "25.05";
    };

    manual = {
      manpages.enable = true;
      json.enable = true;
      html.enable = true;
    };

    news.display = "show";

    programs = {
      atuin = {
        enable = true;

        flags = [ "--disable-up-arrow" ];

        settings = {
          auto_sync = false;
          update_check = false;
          style = "compact";
          show_help = false;

          history_filter = [
            "^ls"
            "^fg"
            "^jobs"
            "^kill"
            "^pkill"
            "^reset"
          ] ++ (map (alias: ''"^${alias}"'') (attrNames config.programs.bash.shellAliases));
        };
      };

      bash = {
        enable = true;
        enableCompletion = true;

        shellAliases = {
          ack = "rg";
          bc = "eva";
          cat = "bat --decorations=never";
          g = "git status --short";
          ga = "git add";
          gaa = "git add -A";
          gaai = "git add --intent-to-add -A";
          gai = "git add --intent-to-add";
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
          j = "jj";
          jc = "jj commit";
          jd = "jj diff";
          jl = "jj log --no-pager --ignore-working-copy";
          ll = mkForce "lsd -l -A";
          ls = mkForce "lsd -l";
          vi = "nvim";
          vim = "nvim";
        };

        sessionVariables = {
          COLORTERM = "truecolor";
          EDITOR = "${config.programs.neovim.package}/bin/nvim";
          CDPATH = ".:${config.dusk.folders.code}:${config.dusk.folders.home}";
          MANPAGER = "${pkgs.less}/bin/less -s -M +Gg";
          MAN_PAGER = "sh -c 'col -bx | bat -l man -p'";
        };

        historySize = 1000000;

        # Ignore common transaction commands and the aliases we've set.
        historyIgnore = [
          "ls"
          "fg"
          "jobs"
          "kill"
          "killall"
          "pkill"
          "reset"
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
          ${concatStringsSep "\n" completeAliases}

          if [ "$(uname -s)" == "Darwin" ]; then
            export PATH="/run/current-system/sw/bin:$PATH:/opt/homebrew/bin"

            ssh-tmux() {
              ssh ''${@} -t "tmux -CC attach-session || tmux -CC new-session"
            }
          fi

          # shellcheck disable=SC2086
          [ -f $HOME/dusk-env.sh ] && . $HOME/dusk-env.sh
        '';
      };

      bat.enable = true;

      btop = {
        enable = true;

        settings = {
          true_color = true;
          vim_keys = true;
        };
      };

      direnv = {
        enable = true;

        nix-direnv.enable = true;

        config.global = {
          load_dotenv = true;
          hide_env_diff = true;
          strict_env = true;
        };
      };

      gpg.enable = true;
      home-manager.enable = true;
      jq.enable = true;
      nix-index.enable = true;

      lsd = {
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

      neovim = {
        enable = true;
        package = pkgs.nightvim;
      };

      readline = {
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

      ssh.hashKnownHosts = true;
      zoxide.enable = true;
    };

    xdg = {
      enable = true;

      configFile."pgcli/config".text = ''
        max_field_width = 
        less_chatty = True
      '';
    };
  };
}
