{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk;
in {
  config = {
    nix = {
      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];

        trusted-substituters =
          [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
        substituters =
          [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
      };
    };

    # Enable v4l2loopback kernel module for android virtual camera
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    environment.systemPackages = with pkgs; [ bash curl file git wget ];

    i18n.defaultLocale = dusk.locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = dusk.locale;
      LC_IDENTIFICATION = dusk.locale;
      LC_MEASUREMENT = dusk.locale;
      LC_MONETARY = dusk.locale;
      LC_NAME = dusk.locale;
      LC_NUMERIC = dusk.locale;
      LC_PAPER = dusk.locale;
      LC_TELEPHONE = dusk.locale;
      LC_TIME = dusk.locale;
    };

    networking.networkmanager.enable = true;

    services.printing.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = lib.mkForce "no";
        PasswordAuthentication = false;
        ChallengeResponseAuthentication = false;
        GSSAPIAuthentication = false;
        KerberosAuthentication = false;
        X11Forwarding = false;
        PermitUserEnvironment = false;
        AllowAgentForwarding = false;
        AllowTcpForwarding = false;
        PermitTunnel = false;
      };
    };

    services.eternal-terminal.enable = true;
    networking.firewall.allowedTCPPorts =
      [ config.services.eternal-terminal.port ];

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

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    system.stateVersion = "23.05";
  };
}
