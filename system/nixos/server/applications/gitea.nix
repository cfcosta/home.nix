let
  inherit (import ./lib.nix) defineService;
  port = 3001;
  subdomain = "git";
in
defineService {
  inherit port subdomain;

  name = "gitea";

  config =
    { config, ... }:
    let
      cfg = config.dusk.system.nixos.server;
    in
    {
      config.services.gitea = {
        inherit (cfg.gitea) enable;

        settings.server = {
          HTTP_ADDRESS = "127.0.0.1";
          HTTP_PORT = port;

          ROOT_URL = "https://${subdomain}.${cfg.domain}";
        };
      };
    };
}
