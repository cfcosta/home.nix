{ config, lib, ... }:
let
  inherit (lib) mkIf;
  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
in
{
  config = mkIf config.dusk.system.nixos.server.enable {
    age.secrets.cloudflare-api-token = {
      file = ../../../secrets/cloudflare-api-token.age;
      owner = "traefik";
    };

    networking.firewall.interfaces.${interface}.allowedTCPPorts = [
      80
      443
    ];

    services.traefik = {
      enable = true;

      staticConfigOptions = {
        accessLog = true;

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log.level = "DEBUG";

        entryPoints = {
          web = {
            address = ":80";
          };

          websecure = {
            address = ":443";
            http.tls = {
              certResolver = "letsencrypt";
            };
          };
        };

        certificatesResolvers.letsencrypt = {
          acme = {
            email = config.dusk.emails.primary;
            storage = "/var/lib/traefik/acme.json";
            dnsChallenge = {
              provider = "cloudflare";
              resolvers = [
                "1.1.1.1:53"
                "8.8.8.8:53"
              ];
            };
          };
        };

        docker.exposedByDefault = false;
      };

      environmentFiles = [ config.age.secrets.cloudflare-api-token.path ];
    };

    users.users.traefik.extraGroups = [ "docker" ];
  };
}
