{ config, lib, ... }:
let
  inherit (lib) mkIf optionals;
  inherit (config.dusk.system.nixos.networking) ip;

  cfg = config.dusk.system.nixos.server;
  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
in
{

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ 53 ];

    services.dnsmasq = {
      enable = true;

      settings = {
        inherit interface;

        server =
          # Point to avahi first if the server is available
          optionals config.services.avahi.enable [
            "127.0.0.1#5353"
            "::1#5353"
          ]
          # If dnscrypt-proxy2 is installed, lets point to it for external requests
          ++ optionals config.dusk.system.nixos.networking.enable [
            "127.0.0.1#5354"
            "::1#5354"
          ]
          ++ config.dusk.system.nixos.networking.extraNameservers;

        domain = "local";
        address = "/.${cfg.domain}/${if ip == null then "192.168.0.1" else ip}";

        expand-hosts = true;
        no-resolv = true;
      };
    };
  };
}
