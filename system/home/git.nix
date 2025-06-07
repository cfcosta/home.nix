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
        "*.log"
        "*.pyc"
        ".DS_Store"
        ".aider.chat.*"
        ".aider.input.*"
        ".aider.tags.*"
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

      signing = {
        inherit (cfg) signByDefault;

        key = null;
        format = "ssh";
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
