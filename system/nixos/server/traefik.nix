{ config, lib, ... }:
let
  inherit (lib) mkIf;

  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
  cfg = config.dusk.system.nixos.server;
in
{
  config = mkIf cfg.enable {
    age.secrets = {
      "localhost.crt".file = ../../../secrets/localhost.crt.age;
      "localhost.key".file = ../../../secrets/localhost.key.age;
    };

    networking.firewall.interfaces.${interface}.allowedTCPPorts = [
      80
      443
    ];

    services.traefik = {
      enable = true;

      staticConfigOptions = {
        global = {
          checkNewVersion = false;
          sendAnonymousUsage = false;
        };

        entryPoints = {
          web = {
            address = ":80";

            http.redirections.entrypoint = {
              to = "websecure";
              scheme = "https";
            };
          };

          websecure.address = ":443";
        };

        providers.docker.exposedByDefault = false;
      };

      dynamicConfigOptions.tls.stores.default.defaultCertificate = {
        certFile = config.age.secrets."localhost.crt".path;
        keyFile = config.age.secrets."localhost.key".path;
      };
    };
  };
}
