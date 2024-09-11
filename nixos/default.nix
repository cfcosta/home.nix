{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkDefault mkForce;
in
{
  imports = [
    ./boot.nix
    ./desktop.nix
    ./virtualisation.nix
    ./nix-index.nix
    ./nvidia.nix
    ./tailscale.nix
    ./privacy.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      bash
      curl
      file
      git
      wget
      unzip
    ];

    i18n.defaultLocale = config.dusk.system.locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.dusk.system.locale;
      LC_IDENTIFICATION = config.dusk.system.locale;
      LC_MEASUREMENT = config.dusk.system.locale;
      LC_MONETARY = config.dusk.system.locale;
      LC_NAME = config.dusk.system.locale;
      LC_NUMERIC = config.dusk.system.locale;
      LC_PAPER = config.dusk.system.locale;
      LC_TELEPHONE = config.dusk.system.locale;
      LC_TIME = config.dusk.system.locale;
    };

    networking.networkmanager.enable = true;

    services = {
      printing.enable = true;

      openssh = {
        enable = true;

        settings = {
          PermitRootLogin = mkForce "no";
          PasswordAuthentication = mkForce false;
          ChallengeResponseAuthentication = mkForce false;
          GSSAPIAuthentication = mkForce false;
          KerberosAuthentication = mkForce false;
          X11Forwarding = mkForce false;
          PermitUserEnvironment = mkForce false;
          AllowAgentForwarding = mkForce false;
          AllowTcpForwarding = mkForce false;
          PermitTunnel = mkForce false;
        };
      };

      pcscd.enable = true;

      # udev rule to support vial keyboards
      udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '';
    };

    networking = {
      hostName = "battlecruiser";
      useDHCP = mkDefault true;
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    users.users.${config.dusk.username} = {
      inherit (config.dusk) initialPassword;

      isNormalUser = true;

      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    system.stateVersion = "24.11";
  };
}
