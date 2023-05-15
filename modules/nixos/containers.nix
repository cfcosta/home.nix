{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.containers;
in {
  options = { devos.containers.enable = mkEnableOption "containers"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose ctop ];

    virtualisation.docker.enable = true;

    users.users.${config.devos.user}.extraGroups = [ "docker" ];
  };
}
