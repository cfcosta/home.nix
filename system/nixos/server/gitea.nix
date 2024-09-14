{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server.gitea;
  interface = config.dusk.system.nixos.networking.defaultNetworkInterface;
in
{
  config = mkIf cfg.enable {
    networking.firewall.interfaces.${interface}.allowedTCPPorts = [
      12345
    ];

    services.gitea = {
      enable = true;

      settings.server = {
        HTTP_ADDRESS = "0.0.0.0";
        HTTP_PORT = 12345;
      };
    };
  };
}
