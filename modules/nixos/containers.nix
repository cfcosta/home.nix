{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.containers;
in {
  options = {
    devos.containers.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable podman
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ podman-tui podman-compose ];

    virtualisation.podman = {
      enable = true;
      dockerCompat = true;

      defaultNetwork.dnsname.enable = true;
    };
  };
}
