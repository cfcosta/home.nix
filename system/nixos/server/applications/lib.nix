{
  exposeHost =
    name: port:
    { config, lib, ... }:
    let
      cfg = config.dusk.system.nixos.server;
    in
    {
      config = lib.mkIf cfg.${name}.enable {
        services.traefik.dynamicConfigOptions.http = {
          routers.${name} = {
            rule = "HostRegexp(`${name}.${cfg.domain}`)";
            service = name;
            entrypoints = [ "websecure" ];
          };

          services.${name}.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString port}"; }
          ];
        };
      };
    };
}
