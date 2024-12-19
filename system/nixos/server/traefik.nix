{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (config) dusk;
  inherit (config.dusk.system.nixos.server) domain;
in
{
  config = mkIf config.dusk.system.nixos.server.enable {
    age.secrets.cloudflare-api-token = {
      file = ../../../secrets/cloudflare-api-token.age;
      owner = "traefik";
    };

    security.acme = {
      acceptTerms = true;

      certs.${domain} = {
        inherit domain;

        email = dusk.emails.primary;
        extraDomainNames = [ "*.${domain}" ];
        group = "traefik";
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets.cloudflare-api-token.path;
      };
    };

    services.traefik = {
      enable = true;

      staticConfigOptions = {
        accessLog = true;

        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        log.level = "INFO";

        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };

          websecure = {
            address = ":443";
            http.tls = {
              certResolver = "letsencrypt";
            };
          };
        };

        docker.exposedByDefault = false;
      };

      dynamicConfigOptions = {
        http.middlewares.strip-prefix.stripPrefix.prefixes = [ "/" ];

        tls = {
          stores.default.defaultCertificate = {
            certFile = "/var/lib/acme/${domain}/cert.pem";
            keyFile = "/var/lib/acme/${domain}/key.pem";
          };

          certificates = [
            {
              certFile = "/var/lib/acme/${domain}/cert.pem";
              keyFile = "/var/lib/acme/${domain}/key.pem";
              stores = "default";
            }
          ];
        };
      };
    };

    users.users.traefik.extraGroups = [ "docker" ];
  };
}
