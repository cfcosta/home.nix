{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home;
in {
  options = {
    devos.home.git = {
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
    home.packages = with pkgs; [ gitg meld ];

    programs.bash.shellAliases = { gg = "gitg"; };

    programs.git = {
      enable = true;

      userName = cfg.name;
      userEmail = cfg.email;

      delta.enable = true;

      signing = {
        key = null;
        signByDefault = cfg.git.signByDefault;
      };

      extraConfig = {
        init.defaultBranch = cfg.git.defaultBranch;
        github.user = cfg.githubUser;
      };
    };
  };
}
