{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    attrNames
    filter
    listToAttrs
    map
    readDir
    ;
  inherit (lib)
    hasSuffix
    mkEnableOption
    mkOption
    removeSuffix
    types
    ;
  inherit (pkgs.stdenv) isLinux;

  isThemeFile = n: (hasSuffix ".nix" n) && !(hasSuffix "default.nix" n);

  themes =
    let
      files = filter isThemeFile (attrNames (readDir ./.));

      toAttr = n: {
        name = removeSuffix ".nix" n;
        value = import ./themes/${n} { inherit config lib pkgs; };
      };
    in
    listToAttrs (map toAttr files);

  currentTheme = themes."${config.dusk.theme.current}";
in
{
  options.dusk = {
    enable = mkEnableOption "dusk-core";

    theme = {
      current = mkOption {
        type = types.enum (attrNames themes);
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
        default = "${config.dusk.folders.home}/Code";
        description = "Where you host your working projects";
      };

      home = mkOption {
        type = types.str;
        default = if isLinux then "/home/${config.dusk.username}" else "/Users/${config.dusk.username}";
        description = "Your home folder";
      };
    };

    alacritty = {
      enable = mkEnableOption "alacritty";

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

    cosmic.enable = mkEnableOption "cosmic";
    media.enable = mkEnableOption "media";
    nvidia.enable = mkEnableOption "nvidia";
    privacy.enable = mkEnableOption "privacy";
    tailscale.enable = mkEnableOption "tailscale";
    virtualisation.enable = mkEnableOption "virtualisation";
    zed.enable = mkEnableOption "zed editor";

    shell = {
      environmentFile = mkOption {
        type = types.str;
        default = "${config.dusk.folders.home}/dusk-env.sh";

        description = ''
          A bash file that is loaded by the shell on each run.
          This is used to set secrets or credentials that we don't want on the repo.
        '';
      };
    };

    tmux = {
      enable = mkEnableOption "tmux";
      showBattery = mkEnableOption "tmux show battery level";
    };
  };
}
