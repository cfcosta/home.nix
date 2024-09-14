{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server;
  host = "cockpit.${cfg.domain}";
in
{
  config = mkIf cfg.cockpit.enable {
    services = {
      cockpit = {
        enable = true;

        port = 10001;

        settings = {
          WebService = {
            AllowUnencrypted = true;
          };
        };
      };

      traefik.dynamicConfigOptions = {
        routers.cockpit = {
          rule = "Host(`${host}`)";
          service = "cockpit";
        };

        services.cockpit.loadBalancer.servers = with config.services.cockpit; [
          { url = "http://127.0.0.1:${toString port}"; }
        ];
      };
    };
  };
}
