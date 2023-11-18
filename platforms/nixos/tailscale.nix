{ lib, pkgs, config, ... }:
with lib; {
  config = {
    services.tailscale.enable = true;
    networking.firewall.checkReversePath = "loose";
  };
}
