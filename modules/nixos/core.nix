{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos;
in {
  imports = [ ./common.nix ];

  options.devos = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable DevOS
      '';
    };

    system = {
      locale = mkOption {
        type = types.str;
        default = "en_US.utf8";
        description = ''
          Locale of the system
        '';
      };
    };

    user = mkOption {
      type = types.str;
      description = ''
        User name of the main user of the system
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bash
      curl
      fd
      file
      ncdu
      neofetch
      ripgrep
      wget
    ];

    i18n.defaultLocale = cfg.system.locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = cfg.system.locale;
      LC_IDENTIFICATION = cfg.system.locale;
      LC_MEASUREMENT = cfg.system.locale;
      LC_MONETARY = cfg.system.locale;
      LC_NAME = cfg.system.locale;
      LC_NUMERIC = cfg.system.locale;
      LC_PAPER = cfg.system.locale;
      LC_TELEPHONE = cfg.system.locale;
      LC_TIME = cfg.system.locale;
    };

    networking.networkmanager.enable = true;

    nixpkgs.config.allowUnfree = true;

    services.printing.enable = true;

    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };
  };
}
