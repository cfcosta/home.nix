{ config, ... }:
let
  cfg = config.dusk.system.git;
in
{
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
        "!.aider.conf.*"
        "**/.direnv/**"
        "**/.git/**"
        "**/.jj/**"
        "**/.obsidian/**"
        "**/.ruff_cache/**"
        "**/.stfolder/**"
        "**/.trash/**"
        "**/.versions/**"
        "**/.vscode/**"
        "**/target/**"
        "**/__pycache__/**"
        "**/node_modules/**"
        "**/result-bin/**"
        "**/result/**"
        "**/target/**"
        "*.lock"
        "*.log"
        "*.pyc"
        ".DS_Store"
        ".aider*"
        ".direnv"
        ".env"
        ".null_ls*"
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

        init = { inherit (cfg) defaultBranch; };

        rebase = {
          autosquash = true;
          autostash = true;
        };
      };
    };
  };
}
