{ config, pkgs, ... }:
let
  cfg = config.dusk.system.git;
in
{
  imports = [ ./gitui ];

  config.programs = {
    git = {
      enable = true;

      userName = config.dusk.name;
      userEmail = config.dusk.emails.primary;

      delta = {
        enable = true;

        options = {
          line-numbers = true;
          navigate = true;
        };
      };

      ignores = [
        "*.pyc"
        ".DS_Store"
        ".aider.chat.*"
        ".aider.input.*"
        ".aider.tags.*"
        ".direnv"
        ".env"
        ".null_ls*"
        ".obsidian"
        ".ruff_cache"
        ".stfolder"
        ".trash"
        ".versions"
        ".vscode"
        "__pycache__"
        "node_modules"
        "result"
        "result-bin"
        "target"
      ];

      signing = {
        inherit (cfg) signByDefault;

        key = null;
      };

      extraConfig = {
        blame.pager = "delta";
        commit.verbose = true;
        github.user = config.dusk.accounts.github;
        help.autocorrect = 10;
        merge.conflictstyle = "diff3";
        pull.ff = "only";
        push.autoSetupRemote = true;
        remote.origin.fetch = "+refs/pull/*/head:refs/remotes/origin/pr/*";
        rerere = {
          enabled = true;
          autoupdate = true;
        };

        diff = {
          algorithm = "histogram";
          colorMoved = "default";
        };

        fetch = {
          prune = true;
          pruneTags = true;
        };

        init = {
          inherit (cfg) defaultBranch;
        };

        rebase = {
          autosquash = true;
          autostash = true;
        };
      };
    };

    jujutsu = {
      enable = true;

      settings = {
        aliases = {
          xl = [
            "log"
            "-r"
            "all()"
          ];

          sync = [
            "rebase"
            "-s"
            "dev"
            "-d"
            "main"
            "-d"
            "all:heads(roots(remote_bookmarks()+::)..(description(glob:'wip:*') | description(glob:'private:*'))-)"
            "--skip-emptied"
          ];
        };

        fix.tools = {
          clang-format = {
            command = [
              "${pkgs.clang-tools}/clang-format"
              "--sort-includes"
              "--assume-filename=$path"
            ];

            patterns = [
              "glob:'**/*.c'"
              "glob:'**/*.h'"
            ];
          };

          rustfmt = {
            command = [
              "${pkgs.rustfmt}/rustfmt"
              "$path"
            ];

            patterns = [
              "glob:'**/*.rs'"
            ];
          };
        };

        git = {
          auto-local-bookmark = true;
          private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
          push-bookmark-prefix = "${config.dusk.accounts.github}/";
        };

        revsets.log = "main-..mine() | bookmarks()";
        snapshot.max-new-file-size = "10MiB";

        signing = {
          sign-all = true;
          backend = "gpg";
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.username()";
          "format_short_id(id)" = "id.shortest()";
        };

        user = {
          inherit (config.dusk) name;
          email = config.dusk.emails.primary;
        };

        ui = {
          default-command = [ "status" ];
          diff-editor = ":builtin";
          diff.format = "git";
          editor = "nvim";
          pager = "delta";
        };
      };
    };
  };
}
