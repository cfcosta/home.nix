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
      avahi.extraServiceFiles.gitea = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">${host}</name>
          <service>
            <type>_http._tcp</type>
            <port>${toString config.services.gitea.settings.server.HTTP_PORT}</port>
          </service>
        </service-group>
      '';

      gitea = {
        enable = true;

        settings.server = {
          HTTP_ADDRESS = "0.0.0.0";
          HTTP_PORT = 10002;

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
