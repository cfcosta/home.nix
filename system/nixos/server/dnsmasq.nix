{ config, lib, ... }:
let
  inherit (lib) mkIf optionals;
  cfg = config.dusk.system.nixos.server;
  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
in
{

  config = mkIf cfg.enable {
    networking.firewall.interfaces.${interface}.allowedUDPPorts = [
      53
    ];

    services.dnsmasq = {
      enable = true;

      settings = {
        inherit interface;

        # If dnscrypt-proxy2 is installed, lets point to it for external requests
        server =
          optionals config.dusk.system.nixos.networking.enable [
            "127.0.0.1#5354"
            "::1#5354"
          ]
          ++ config.dusk.system.nixos.networking.extraNameservers;

        domain = "local";
        address = "/.${cfg.domain}/0.0.0.0";

        expand-hosts = true;
        no-resolv = true;
      };
    };
  };
}
