{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server;
  host = "gitea.${cfg.domain}";
in
{
  config = mkIf cfg.gitea.enable {
    services = {
      gitea = {
        enable = true;

        settings.server = {
          HTTP_ADDRESS = "0.0.0.0";
          HTTP_PORT = 10001;

          ROOT_URL = "https://${host}";
        };
      };

      traefik.dynamicConfigOptions = {
        routers.gitea = {
          rule = "Host(`${host}`)";
          service = "gitea";
        };

        services.gitea.loadBalancer.servers = with config.services.gitea.settings.server; [
          { url = "http://127.0.0.1:${toString HTTP_PORT}"; }
        ];
      };
    };
  };
}
