{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    attrNames
    concatStringsSep
    map
    ;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (lib) mapAttrsToList mkForce mkIf;
  inherit (pkgs.stdenv) isDarwin isLinux;

  envFileSetup =
    if config.dusk.shell.environmentFile != null then
      ''
        # shellcheck source=/dev/null
        [ -f ${config.dusk.shell.environmentFile} ] && . ${config.dusk.shell.environmentFile}
      ''
    else
      "";

  darwinSetup =
    if isDarwin then
      ''
        # MacOS by default does not load the completions set by Nix, so this
        # function fixes that.
        loadCompletions() {
        	local dir="''${1}/share/bash-completion/completions"

        	if [ ! -d "''${dir}" ]; then
        		return
        	fi

        	for f in "''${dir}"/*; do
        		# shellcheck source=/dev/null
        		. "''${f}"
        	done
        }

        loadCompletions "/run/current-system/sw"
        loadCompletions "''${HOME}/.nix-profile"
        loadCompletions "/nix/var/nix/profiles/default"

        unset -f loadCompletions

        if [ -e /run/current-system/sw/etc/profile.d/nix-daemon.sh ]; then
          . /run/current-system/sw/etc/profile.d/nix-daemon.sh
        fi

        export PATH="/run/current-system/sw/bin:$PATH:/opt/homebrew/bin"
      ''
    else
      "";
in
{
  imports = [
    ./tmux
    ./zed
    ./alacritty.nix
    ./git.nix
    ./media.nix
  ];

  config = {
    age.secrets = {
      "env.sh.age".file = ../secrets/env.sh.age;
      "nix.conf.age".file = ../secrets/nix.conf.age;
    };

    home = {
      inherit (config.dusk) username;

      homeDirectory = mkForce config.dusk.folders.home;

      file =
        {
          ".config/nix/nix.conf".source = config.age.secrets."nix.conf.age".path;
        }
        // mkIf isLinux {
          ".cache/nix-index".source = mkOutOfStoreSymlink "/var/db/nix-index";
        };

      packages = with pkgs; [
        (nerdfonts.override { fonts = [ "Inconsolata" ]; })
      ];
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
            "^cd"
            "^cat"
            "^fg"
            "^jobs"
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
          CDPATH = ".:${config.dusk.folders.code}:${config.dusk.folders.home}";
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

          ${concatStringsSep "\n" (
            map (alias: "complete -F _complete_alias ${alias}") (attrNames config.programs.bash.shellAliases)
          )}

          ${darwinSetup}
          ${envFileSetup}

          # shellcheck source=/dev/null
          . ${toString config.age.secrets."env.sh.age".path}
        '';
      };

      bat = {
        enable = true;

        config.theme = config.dusk.theme.settings.bat;
      };

      btop = {
        enable = true;

        settings = {
          color_theme = config.dusk.theme.settings.btop;

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

      starship = {
        enable = true;
        enableBashIntegration = true;
        settings = config.dusk.theme.settings.starship;
      };

      zoxide.enable = true;
    };

    xdg.configFile."pgcli/config".text = ''
      max_field_width = 
      less_chatty = True
      syntax_style = "${config.dusk.theme.settings.pgcli}"
    '';
  };
}
