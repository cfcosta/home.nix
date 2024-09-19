{ config, lib, ... }:
let
  cfg = config.dusk.system.nixos.server;

  inherit (lib) mkIf optionals;
  inherit (config.dusk.system.nixos.networking) ip defaultNetworkInterface nameservers;
  inherit (cfg.dnsmasq) targetLocal;

  interface = defaultNetworkInterface;

  localIp = if ip == null then "192.168.0.1" else ip;
  target = if targetLocal == null then localIp else targetLocal;
in
{

  config = mkIf cfg.dnsmasq.enable {
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
            [
              "127.0.0.1#5354"
              "::1#5354"
            ]
            # Then, if not found, let's try avahi
            ++ optionals config.services.avahi.enable [
              "127.0.0.1#5353"
              "::1#5353"
            ]
            ++ nameservers;

          domain = "local";
          address = "/.${cfg.domain}/${target}";

          expand-hosts = true;
          no-resolv = true;
        };
      };
    };
  };
}
