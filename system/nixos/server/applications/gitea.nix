{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server;

  domain = "gitea.${cfg.domain}";
  port = 10002;

  hostConfig = (import ./lib/expose-host.nix).exposeHost {
    inherit domain port;
    name = "gitea";
  };
in
{
  config =
    mkIf cfg.gitea.enable {
      services.gitea = {
        enable = true;

        settings.server = {
          HTTP_ADDRESS = "127.0.0.1";
          HTTP_PORT = port;

          ROOT_URL = "https://${domain}";
        };
      };
    }
    // hostConfig;
}
