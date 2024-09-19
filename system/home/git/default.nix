{ config, ... }:
let
  cfg = config.dusk.system.git;
in
{
  imports = [ ./gitui ];

  config.programs.git = {
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
      ".aider.*"
      ".direnv"
      ".env"
      ".null_ls*"
      ".vscode"
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
}
