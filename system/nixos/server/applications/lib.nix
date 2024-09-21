{
  defineService =
    {
      name,
      description ? "Enable service ${name}",

      port ? null,
      subdomain ? name,

      config ? {
        services.${name} = {
          inherit (config.dusk.system.nixos.server.${name}) enable;
          openFirewall = false;
        };
      },
    }:
    args:
    let
      inherit (args.lib) mkIf mkOption types;

      cfg = args.config.dusk.system.nixos.server;
      listenPort = if port == null then args.config.services.${name}.port else port;
    in
    {
      options.dusk.system.nixos.server.${name}.enable = mkOption {
        inherit description;

        type = types.bool;
        default = cfg.enable;
      };

      config = mkIf cfg.${name}.enable (
        config
        // {
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
        }
      );
    };
}
