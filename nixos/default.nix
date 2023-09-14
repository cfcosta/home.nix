{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk;
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

  options.dusk = {
    enable = mkEnableOption "dusk-core";

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
      default = "dusk";
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;

    nix.extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
    '';

    nix.settings = {
      trusted-substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
      substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
    };

    system.stateVersion = "23.05";

    environment.systemPackages = with pkgs; [ bash curl file git wget src-cli ];

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

    programs.mosh.enable = true;

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "gnome3";
    };

    services.pcscd.enable = true;

    users.users.${config.dusk.user} = {
      isNormalUser = true;
      extraGroups = [ "networkmanager" "wheel" ];
      inherit (config.dusk) initialPassword;
    };

    # udev rule to support vial keyboards
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';
  };
}
