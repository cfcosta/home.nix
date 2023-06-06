{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.containers;
in {
  options = { dusk.containers.enable = mkEnableOption "containers"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose ctop ];

    virtualisation.docker.enable = true;

    users.users.${config.dusk.user}.extraGroups = [ "docker" ];
  };
}
