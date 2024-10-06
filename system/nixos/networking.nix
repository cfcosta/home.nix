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

    environment.systemPackages = with pkgs; [
      dnsutils
      inetutils
      mitmproxy
      tcpdump
      tshark
    ];

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
          enable = true;

          allowInterfaces = [
            net.defaultNetworkInterface
          ] ++ optionals net.tailscale.enable [ "tailscale0" ];

          publish = {
            enable = true;

            domain = true;
            userServices = true;
            workstation = true;
          };

          nssmdns4 = true;
          nssmdns6 = true;
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
