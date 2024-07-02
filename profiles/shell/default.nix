{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (pkgs.stdenv) isLinux;
in
{
  options.protoss.protoss.shell = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the protoss shell config";
    };
  };

  config = mkIf config.protoss.shell.enable {
    environment.systemPackages = with pkgs; [
      bashInteractive
      curl
      file
      git
      unzip
      wget
    ];

    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    programs = {
      bash.enable = true;
      gnupg.enable = true;
    };

    system.stateVersion = if isLinux then "24.05" else 4;
  };
}
