{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
  inherit (pkgs.stdenv) isLinux;
in
{
  options.dusk = {
    initialPassword = mkOption {
      type = types.str;
      description = "Initial password for the created user in the system ";
      default = "dusk";
    };

    system = {
      hostname = mkOption {
        type = types.str;
        description = "The hostname of the system on the network";
        default = "dusk";
      };

      locale = mkOption {
        type = types.str;
        default = "en_US.utf8";
        description = "Locale of the system ";
      };

      timezone = mkOption {
        type = types.str;
        default = "America/Sao_Paulo";
        description = "Timezone to use for the system";
      };
    };

    accounts.github = mkOption { type = types.str; };
    email = mkOption { type = types.str; };
    name = mkOption { type = types.str; };
    username = mkOption {
      type = types.str;
      description = "User name of the main user of the system ";
    };

    folders =
      let
        home = if isLinux then "/home/${config.dusk.username}" else "/Users/${config.dusk.username}";
      in
      {
        code = mkOption {
          type = types.str;
          description = "Where you host your working projects";
          default = "${home}/Code";
        };

        downloads = mkOption {
          type = types.str;
          description = "Where you host your Downloads";
          default = "${home}/Downloads";
        };

        home = mkOption {
          type = types.str;
          description = "Your home folder";
          default = home;
        };
      };

    alacritty = {
      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata NerdFont Mono";
        };

        size = mkOption {
          type = types.float;
          default = 14.0;
        };
      };
    };

    git = {
      signByDefault = mkOption {
        type = types.bool;
        default = true;
      };

      defaultBranch = mkOption {
        type = types.str;
        default = "main";
      };
    };

    shell = {
      environmentFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          A bash file that is loaded by the shell on each run.
          This is used to set secrets or credentials that we don't want on the repo.
        '';
      };
    };

    tmux.showBattery = mkEnableOption "tmux show battery level";
  };
}
