{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (import ./lib.nix) exposeHost;

  cfg = config.dusk.system.nixos.server;
  port = 3001;
in
{
  imports = [
    (exposeHost "gitea" port)
  ];

  config = mkIf cfg.gitea.enable {
    services.gitea = {
      enable = true;

      settings.server = {
        HTTP_ADDRESS = "127.0.0.1";
        HTTP_PORT = port;

        ROOT_URL = "https://gitea.${cfg.domain}";
      };
    };
  };
}
