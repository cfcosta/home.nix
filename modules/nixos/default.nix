{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos;
in {
  imports = [
    ./containers.nix
    ./gaming.nix
    ./gnome.nix
    ./icognito.nix
    ./libvirt.nix
    ./nvidia.nix
    ./sound.nix
    ./tailscale.nix
    ./virtualbox.nix
  ];

  options.devos = {
    enable = mkEnableOption "devos-core";

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

    initialPassword = mkOption {
      type = types.str;
      description = ''
        Initial password for the created user in the system
      '';
      default = "devos";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    system.stateVersion = "23.05";

    environment.systemPackages = with pkgs; [ bash curl file git wget ];

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

    services.printing.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "no";
        PasswordAuthentication = false;
      };
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };

    services.pcscd.enable = true;

    users.users.${config.devos.user} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
      inherit (config.devos) initialPassword;
    };
  };
}
