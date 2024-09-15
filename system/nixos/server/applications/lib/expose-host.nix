{
  exposeHost =
    {
      name,
      domain,
      port,
    }:
    {
      services = {
        avahi.extraServiceFiles = {
          "${name}" = ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">${name}</name>
              <service>
                <type>_http._tcp</type>
                <port>80</port>
              </service>
            </service-group>
          '';

          "${name}-https" = ''
            <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
            <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
            <service-group>
              <name replace-wildcards="yes">${name}-https</name>
              <service>
                <type>_http._tcp</type>
                <port>443</port>
              </service>
            </service-group>
          '';

        };

        traefik.dynamicConfigOptions = {
          routers.${name} = {
            rule = "Host(`${domain}`)";
            service = name;
          };

          services.${name}.loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString port}"; }
          ];
        };
      };
    };
}
