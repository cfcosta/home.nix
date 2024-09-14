{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  hostConfig = (import ./lib/expose-host.nix).exposeHost {
    inherit (config.services.cockpit) port;

    name = "cockpit";
    domain = "cockpit.${cfg.domain}";
  };

  cfg = config.dusk.system.nixos.server;
in
{
  config =
    mkIf cfg.cockpit.enable {
      services.cockpit = {
        enable = true;
        port = 10001;

        settings.WebService.AllowUnencrypted = true;
      };
    }
    // hostConfig;
}
