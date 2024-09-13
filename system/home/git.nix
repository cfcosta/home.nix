{ config, ... }:
{
  config = {
    programs.git = {
      enable = true;

      userName = config.dusk.name;
      userEmail = config.dusk.email;

      delta = {
        enable = true;

        options = {
          theme = config.dusk.theme.settings.delta-pager;

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

      includes = [
        { path = ../common/themes/git/catppuccin.gitconfig; }
      ];

      signing = {
        inherit (config.dusk.git) signByDefault;

        key = null;
      };

      extraConfig = {
        blame.pager = "delta";
        commit.verbose = true;
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        github.user = config.dusk.accounts.github;
        help.autocorrect = 10;
        init.defaultBranch = config.dusk.git.defaultBranch;
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
