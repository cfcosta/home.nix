{
  config,
  flavor,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dusk) username initialPassword;
  inherit (config.dusk.system) locale timezone;
  inherit (lib)
    mkDefault
    mkForce
    mkIf
    mkOption
    types
    ;

  default = flavor == "nixos";
  cfg = config.dusk.system.nixos;
in
{
  imports = [
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.default
    inputs.nix-flatpak.nixosModules.nix-flatpak

    ./ai.nix
    ./boot.nix
    ./desktop.nix
    ./networking.nix
    ./nvidia.nix
    ./server
    ./virtualisation.nix
  ];

  options.dusk.system.nixos = {
    enable = mkOption {
      inherit default;

      type = types.bool;
      description = "Whether or not to enable NixOS Modules";
    };

    createUser = mkOption {
      inherit default;

      type = types.bool;
      description = "Whether or not to create the main user";
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.availableKernelModules = [
      "ahci"
      "nvme"
      "sd_mod"
      "thunderbolt"
      "usb_storage"
      "usbhid"
      "xhci_pci"
    ];

    catppuccin.enable = true;

    environment = {
      defaultPackages = mkForce [ ];
      systemPackages = with pkgs; [ killall ];
    };

    hardware.graphics.enable = true;

    i18n.defaultLocale = locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = locale;
      LC_IDENTIFICATION = locale;
      LC_MEASUREMENT = locale;
      LC_MONETARY = locale;
      LC_NAME = locale;
      LC_NUMERIC = locale;
      LC_PAPER = locale;
      LC_TELEPHONE = locale;
      LC_TIME = locale;
    };

    time.timeZone = timezone;

    services = {
      eternal-terminal.enable = true;
      printing.enable = mkForce false;

      openssh = {
        enable = true;

        settings = {
          PermitRootLogin = mkForce "no";
          PasswordAuthentication = mkForce false;
          ChallengeResponseAuthentication = mkForce false;
          X11Forwarding = mkForce false;
          PermitUserEnvironment = mkForce false;
          AllowAgentForwarding = mkForce false;
          AllowTcpForwarding = mkForce false;
          PermitTunnel = mkForce true;
        };
      };

      pcscd.enable = true;

      # udev rule to support vial keyboards
      udev.extraRules = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
      '';
    };

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    security = {
      audit = {
        enable = mkDefault true;
        rules = [ "-a exit,always -F arch=b64 -S execve" ];
      };

      auditd.enable = mkDefault true;
    };

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    users.users.${username} = mkIf cfg.createUser {
      inherit initialPassword;

      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    system.stateVersion = "25.05";
  };
}
