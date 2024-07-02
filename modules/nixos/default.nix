{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk;
in
{
  imports = [
    ./ai.nix
    ./amd.nix
    ./containers.nix
    ./gaming.nix
    ./gnome.nix
    ./libvirt.nix
    ./nix-index.nix
    ./nvidia.nix
    ./sound.nix
    ./tailscale.nix
    ./vpn.nix
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

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    services.pcscd.enable = true;

    users.users.${config.dusk.user} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      inherit (config.dusk) initialPassword;
    };

    # Make clock compatible with windows (for dual boot)
    time.hardwareClockInLocalTime = true;

    system.stateVersion = "23.11";
  };
}
