{ config, lib, ... }:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.dusk.system.nixos.server.enable {
    age.secrets.cloudflare-api-token = {
      file = ../../../secrets/cloudflare-api-token.age;
      owner = "traefik";
    };

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
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };
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

      dynamicConfigOptions.http.middlewares = {
        strip-prefix.stripPrefix.prefixes = [ "/" ];
      };

      environmentFiles = [ config.age.secrets.cloudflare-api-token.path ];
    };

    users.users.traefik.extraGroups = [ "docker" ];
  };
}
