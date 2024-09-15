{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  port = 10001;

  hostConfig = (import ./lib/expose-host.nix).exposeHost {
    inherit port;

    name = "cockpit";
    domain = "cockpit.${cfg.domain}";
  };

  cfg = config.dusk.system.nixos.server;
in
{
  config =
    mkIf cfg.cockpit.enable {
      services.cockpit = {
        inherit port;

        enable = true;

        settings.WebService.AllowUnencrypted = true;
      };
    }
    // hostConfig;
}
