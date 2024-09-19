{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (import ./lib.nix) exposeHost;

  cfg = config.dusk.system.nixos.server;
  port = 3000;
in
{
  imports = [
    (exposeHost "cockpit" port)
  ];

  config = mkIf cfg.cockpit.enable {
    services.cockpit = {
      inherit port;

      enable = true;
      settings.WebService.AllowUnencrypted = true;
    };
  };
}
