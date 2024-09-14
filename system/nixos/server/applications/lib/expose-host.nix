{
  exposeHost =
    {
      name,
      domain,
      port,
    }:
    {
      services.traefik.dynamicConfigOptions = {
        routers.${name} = {
          rule = "Host(`${domain}`)";
          service = name;
        };

        services.${name}.loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString port}"; }
        ];
      };
    };
}
