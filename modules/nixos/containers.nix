{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.containers;
in {
  options = {
    devos.containers.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable Docker
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ docker-compose ctop ] ++ optionals config.devos.nvidia.enable [ nvidia-docker ];

    virtualisation.docker.enable = true;

    users.users.${config.devos.user}.extraGroups = [ "docker" ];
  };
}
