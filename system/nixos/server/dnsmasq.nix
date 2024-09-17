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

    services = {
      dnscrypt-proxy2 = {
        enable = true;
        settings.listen_addresses = [ "127.0.0.1:5354" ];
      };

      dnsmasq = {
        enable = true;
        alwaysKeepRunning = true;

        settings = {
          inherit interface;

          server =
            # Point to dnscrypt as the first entrypoint
            optionals config.dusk.system.nixos.networking.enable [
              "127.0.0.1#5354"
              "::1#5354"
            ]
            # Then, if not found, let's try avahi
            ++ optionals config.services.avahi.enable [
              "127.0.0.1#5353"
              "::1#5353"
            ]
            ++ config.dusk.system.nixos.networking.nameservers;

          domain = "local";
          address = "/.${cfg.domain}/${if ip == null then "192.168.0.1" else ip}";

          expand-hosts = true;
          no-resolv = true;
        };
      };
    };
  };
}
