{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos;
in {
  imports = [ ./common.nix ];

  options.devos.icognito = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable Icognito Mode (i2p, tor)
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ tor-browser-bundle-bin ];

    services.i2p.enable = true;
  };
}
