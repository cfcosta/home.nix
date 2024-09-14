{ config, ... }:
let
  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
in
{
  config = {
    age.secrets.cert-key.file = ../../../secrets/localhost.key.age;

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
        certFile = builtins.toString ../../certificates/localhost.crt;
        keyFile = config.age.secrets.cert-key.path;
      };
    };
  };
}
