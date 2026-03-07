{ config, ... }:
let
  cfg = config.dusk.system.git;
  inherit (config.dusk) name;
  email = config.dusk.emails.primary;
in
{
  config.programs = {
    delta = {
      enable = true;

      options = {
        enableGitIntegration = true;
        line-numbers = true;
        navigate = true;
      };
    };

    git = {
      enable = true;

      ignores = [
        "*.aider*"
        "*.log"
        "*.pyc"
        ".DS_Store"
        ".claude/**"
        ".direnv"
        ".direnv/**"
        ".env"
        ".git/**"
        ".jj/**"
        ".null_ls*"
        ".obsidian/**"
        ".ruff_cache/**"
        ".stfolder/**"
        ".trash/**"
        ".versions/**"
        ".vscode/**"
        "__pycache__/**"
        "node_modules/**"
        "result-bin/**"
        "result/**"
        "target/**"
        "target/**"
      ];

      settings = {
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

        user = { inherit name email; };
      };

      signing = {
        inherit (cfg) signByDefault;

        key = null;
        format = "ssh";
      };
    };
  };
}
