{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server.gitea;
  interface = config.dusk.system.networking.defaultNetworkInterface;
in
{
  config = mkIf cfg.enable {
    networking.firewall.interfaces.${interface}.allowedTCPPorts = [
      12345
    ];

    services.gitea = {
      inherit (cfg.gitea) enable;

      settings.server = {
        HTTP_ADDRESS = "10.0.0.0";
        HTTP_PORT = 12345;
      };
    };
  };
}
