{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (builtins)
    attrNames
    filter
    readDir
    ;
  inherit (lib)
    hasSuffix
    mkEnableOption
    mkOption
    removeSuffix
    types
    ;

  themeFiles = filter (hasSuffix ".nix") (attrNames (readDir ./defaults/themes));
  themes = map (removeSuffix ".nix") themeFiles;

  currentTheme = import ./defaults/themes/${config.dusk.theme.current}.nix {
    inherit config lib pkgs;
  };
in
{
  options.dusk = {
    theme = {
      current = mkOption {
        type = types.enum themes;
        default = "dracula";
      };

      settings = mkOption {
        type = types.attrs;
        default = currentTheme;
      };
    };

    initialPassword = mkOption {
      type = types.str;
      description = ''Initial password for the created user in the system '';
      default = "dusk";
    };

    system = {
      locale = mkOption {
        type = types.str;
        default = "en_US.utf8";
        description = ''Locale of the system '';
      };
    };

    accounts.github = mkOption { type = types.str; };
    email = mkOption { type = types.str; };
    name = mkOption { type = types.str; };
    username = mkOption {
      type = types.str;
      description = ''User name of the main user of the system '';
    };

    folders = {
      code = mkOption {
        type = types.str;
        description = "Where you host your working projects";
      };

      home = mkOption {
        type = types.str;
        description = "Your home folder";
      };
    };

    alacritty = {
      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata";
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
