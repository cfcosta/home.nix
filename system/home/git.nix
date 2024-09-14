{ config, ... }:
let
  cfg = config.dusk.system.git;
in
{
  config = {
    programs.git = {
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
        ".DS_Store"
        ".direnv"
        ".env"
        ".null_ls*"
        ".vscode"
        "result"
        "result-bin"
      ];

      signing = {
        inherit (cfg) signByDefault;

        key = null;
      };

      extraConfig = {
        blame.pager = "delta";
        commit.verbose = true;

        diff = {
          algorithm = "histogram";
          colorMoved = "default";
        };

        github.user = config.dusk.accounts.github;
        help.autocorrect = 10;

        init = {
          inherit (cfg) defaultBranch;
        };

        merge.conflictstyle = "diff3";
        pull.ff = "only";
        push.autoSetupRemote = true;

        rebase = {
          autosquash = true;
          autostash = true;
        };

        rerere.enabled = true;
      };
    };

  };
}
