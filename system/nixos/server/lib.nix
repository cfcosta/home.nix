{
  exposeHost =
    {
      name,
      domain,
      port,
    }:
    {
      services = {
        avahi.extraServiceFiles.${name} = ''
          <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">${domain}</name>
            <service>
              <type>_http._tcp</type>
              <port>${toString port}</port>
            </service>
          </service-group>
        '';

        traefik.dynamicConfigOptions = {
          routers.gitea = {
            rule = "Host(`${domain}`)";
            service = "gitea";
          };

          services.gitea.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString port}"; }
          ];
        };
      };
    };
}
