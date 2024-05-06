{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk;
in {
  imports = [
    ./ai.nix
    ./amd.nix
    ./benchmarking.nix
    ./containers.nix
    ./gaming.nix
    ./gnome.nix
    ./icognito.nix
    ./libvirt.nix
    ./nix-index.nix
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
    # Make the whole system use the same <nixpkgs> as this flake.
    environment.etc."nix/inputs/nixpkgs".source = "${pkgs.dusk.inputs.nixpkgs}";
    environment.etc."nix/inputs/nix-darwin".source =
      "${pkgs.dusk.inputs.nix-darwin}";

    nix = {
      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      };

      # Configure nix to use the flake's nixpkgs
      registry.nixpkgs.flake = pkgs.dusk.inputs.nixpkgs;
      registry.nix-darwin.flake = pkgs.dusk.inputs.nix-darwin;
      nixPath = lib.mkForce [ "/etc/nix/inputs" ];
    };

    # Enable v4l2loopback kernel module for android virtual camera
    boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    boot.kernelModules = [ "v4l2loopback" ];

    environment.systemPackages = with pkgs; [ bash curl file git wget unzip ];

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
      pinentryPackage = pkgs.pinentry-gnome3;
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

    system.stateVersion = "23.11";
  };
}
