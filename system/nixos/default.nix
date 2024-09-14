{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (config.dusk) system username initialPassword;
  inherit (lib) mkDefault mkForce mkIf;
in
{
  imports = [
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.default
    inputs.nixos-cosmic.nixosModules.default

    ./boot.nix
    ./desktop.nix
    ./networking.nix
    ./virtualisation.nix
    ./nvidia.nix
    ./server
  ];

  config = {
    catppuccin.enable = true;

    environment.defaultPackages = mkForce [ ];

    i18n.defaultLocale = system.locale;

    i18n.extraLocaleSettings = {
      LC_ADDRESS = system.locale;
      LC_IDENTIFICATION = system.locale;
      LC_MEASUREMENT = system.locale;
      LC_MONETARY = system.locale;
      LC_NAME = system.locale;
      LC_NUMERIC = system.locale;
      LC_PAPER = system.locale;
      LC_TELEPHONE = system.locale;
      LC_TIME = system.locale;
    };

    time.timeZone = system.timezone;

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

    users.users.${username} = mkIf config.dusk.system.nixos.createUser {
      inherit initialPassword;

      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    system.stateVersion = "24.11";
  };
}
