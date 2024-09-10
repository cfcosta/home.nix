{
  lib,
  config,
  ...
}:
lib.optionalAttrs config.dusk.tailscale.enable {
  services.tailscale.enable = true;
}
