{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.tailscale;
in {
  imports = [ ./common.nix ];

  options.devos.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable DevOS
      '';
    };
  };

  config = mkIf cfg.enable {
    services.tailscale.enable = true;
    networking.firewall.checkReversePath = "loose";
  };
}
