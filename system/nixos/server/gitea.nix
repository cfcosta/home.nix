{ dusk-lib, ... }:
let
  port = 3001;
  subdomain = "git";
in
dusk-lib.defineService {
  inherit port subdomain;

  name = "gitea";

  config =
    { config, ... }:
    {
      config.services.gitea = {
        enable = true;

        settings.server = {
          HTTP_ADDRESS = "127.0.0.1";
          HTTP_PORT = port;

          ROOT_URL = "https://${subdomain}.${config.dusk.system.nixos.server.domain}";
        };
      };
    };
}
