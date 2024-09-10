{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    mkForce
    ;
in
{
  imports = [
    ./ai.nix
    ./virtualisation.nix
    ./desktop.nix
    ./nix-index.nix
    ./nvidia.nix
    ./tailscale.nix
    ./privacy.nix
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

  config = mkIf config.dusk.enable {
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

    services.printing.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = mkForce "no";
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

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    services.pcscd.enable = true;

    users.users.${config.dusk.user} = {
      inherit (config.dusk) initialPassword;

      isNormalUser = true;

      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };

    # udev rule to support vial keyboards
    services.udev.extraRules = ''
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
    '';

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    system.stateVersion = "24.11";
  };
}
