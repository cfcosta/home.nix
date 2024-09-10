{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk;
  inherit (lib) mkOption types mkIf;
in
{
  options = {
    dusk.git = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      signByDefault = mkOption {
        type = types.bool;
        default = true;
      };

      defaultBranch = mkOption {
        type = types.str;
        default = "main";
      };
    };
  };

  config = mkIf cfg.git.enable {
    home.packages = with pkgs; [
      git-bug
      git-lfs
    ];

    programs.git = {
      enable = true;
      lfs.enable = true;

      userName = cfg.name;
      userEmail = cfg.email;

      delta = {
        enable = true;
        options = {
          line-numbers = true;
          navigate = true;
          theme = config.dusk.currentTheme.delta-pager;
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
        key = null;
        inherit (cfg.git) signByDefault;
      };

      extraConfig = {
        blame.pager = "delta";
        commit.verbose = true;
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        github.user = cfg.accounts.github;
        help.autocorrect = 10;
        init.defaultBranch = cfg.git.defaultBranch;
        merge.conflictstyle = "diff3";
        pull.ff = "only";
        push.autoSetupRemote = true;
        rebase = {
          autosquash = true;
          autostash = true;
        };
        rerere.enabled = true;
        url."git@github.com:".insteadOf = "https://github.com/";
      };
    };
  };
}
