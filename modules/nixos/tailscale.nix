{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.dusk.tailscale.enable = mkEnableOption "tailscale";

  config = mkIf config.dusk.tailscale.enable {
    services.tailscale.enable = true;
  };
}
