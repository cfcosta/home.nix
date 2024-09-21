{
  defineService =
    {
      name,
      port ? null,
      subdomain ? name,
      config ?
        { config, ... }:
        {
          services.${name} = {
            inherit (config.dusk.system.nixos.server.${name}) enable;
            openFirewall = false;
          };
        },
    }:
    args:
    let
      inherit (args.lib) mkIf;

      cfg = args.config.dusk.system.nixos.server;
      listenPort = if port == null then args.config.services.${name}.port else port;
    in
    {
      imports = [ config ];

      config = mkIf cfg.${name}.enable {
        services.traefik.dynamicConfigOptions.http = {
          routers.${subdomain} = {
            rule = "Host(`${subdomain}.${cfg.domain}`)";
            service = name;
            entrypoints = [ "websecure" ];
            tls = true;
          };

          services.${name}.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString listenPort}"; }
          ];
        };
      };
    };
}
