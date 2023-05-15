{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.tailscale;
in {
  options.devos.tailscale.enable = mkEnableOption "tailscale";

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.checkReversePath = "loose";
  };
}
