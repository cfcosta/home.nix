{ config, ... }:
let
  inherit (import ./lib.nix) defineService;
  cfg = config.dusk.system.nixos.server;

  port = 3001;
  subdomain = "git";

  service = defineService {
    inherit port subdomain;

    name = "gitea";

    config.services.gitea = {
      enable = true;

      settings.server = {
        HTTP_ADDRESS = "127.0.0.1";
        HTTP_PORT = port;

        ROOT_URL = "https://${subdomain}.${cfg.domain}";
      };
    };
  };
in
{
  imports = [ service ];
}
