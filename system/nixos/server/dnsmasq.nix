{ config, lib, ... }:
let
  inherit (lib) optionals;
  cfg = config.dusk.system.nixos.server;
in
{

  config = {
    services.dnsmasq = {
      enable = true;

      settings = {
        # If dnscrypt-proxy2 is installed, lets point to it for external requests
        server =
          optionals config.dusk.system.nixos.networking.enable [
            "127.0.0.1#5354"
            "::1#5354"
          ]
          ++ config.dusk.system.nixos.networking.extraNameservers;

        interface = "lo";
        domain = "local";
        address = "/.${cfg.domain}/127.0.0.1";

        expand-hosts = true;
        no-resolv = true;
      };
    };
  };
}
