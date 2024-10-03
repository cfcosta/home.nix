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
      "*.pyc"
      ".DS_Store"
      ".aider.chat.*"
      ".aider.input.*"
      ".aider.tags.*"
      ".direnv"
      ".env"
      ".null_ls*"
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
      rerere.enabled = true;

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
}
