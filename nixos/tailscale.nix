{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.tailscale;
in {
  options.dusk.tailscale.enable = mkEnableOption "tailscale";

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.checkReversePath = "loose";
  };
}
