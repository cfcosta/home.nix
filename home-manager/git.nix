{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home;
in {
  options = {
    dusk.home.git = {
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
    home.packages = with pkgs; [ git-bug ];

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = cfg.name;
          email = cfg.email;
        };
        ui.default-command = "status";
      };
    };

    programs.git = {
      enable = true;

      userName = cfg.name;
      userEmail = cfg.email;

      delta.enable = true;

      ignores = [ ".direnv" "result" "result-bin" ];

      signing = {
        key = null;
        inherit (cfg.git) signByDefault;
      };

      extraConfig = {
        commit.verbose = true;
        github.user = cfg.accounts.github;
        init.defaultBranch = cfg.git.defaultBranch;
        pull.ff = "only";
        push.autoSetupRemote = true;
      };
    };
  };
}