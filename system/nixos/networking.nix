{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;

  cfg = config.dusk.system.nixos.networking;
in
{
  config = mkIf cfg.enable {
    age.secrets = mkIf cfg.mullvad.enable {
      mullvad = {
        file = ../../secrets/mullvad.age;
        path = "/etc/NetworkManager/system-connections/mullvad.nmconnection";
        mode = "0600";
      };
    };

    environment = {
      systemPackages = with pkgs; [
        dnsutils
        inetutils
        mitmproxy
        tcpdump
        tshark
      ];
    };

    networking = {
      firewall = {
        allowedTCPPorts = optionals config.services.eternal-terminal.enable [ 2022 ];
        checkReversePath = false;
        trustedInterfaces = optionals cfg.tailscale.enable [ "tailscale0" ];
      };

      networkmanager.enable = true;
    };

    services = {
      avahi =
        let
          net = config.dusk.system.nixos.networking;
        in
        {
          enable = lib.mkForce false;

          allowInterfaces = [
            net.defaultNetworkInterface
          ] ++ optionals net.tailscale.enable [ "tailscale0" ];

          publish = {
            enable = lib.mkForce false;

            domain = lib.mkForce false;
            userServices = lib.mkForce false;
            workstation = lib.mkForce false;
          };

          nssmdns4 = lib.mkForce false;
          nssmdns6 = lib.mkForce false;
        };

      tailscale = {
        inherit (cfg.tailscale) enable;
      };
    };

    users.users.${config.dusk.username}.extraGroups = [
      "networkmanager"
      "wireshark"
    ];
  };
}
