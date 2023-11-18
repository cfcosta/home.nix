{ lib, pkgs, config, ... }:
with lib; {
  config = {
    environment.systemPackages = with pkgs; [ docker-compose ctop ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };

      podman = {
        enable = true;
        autoPrune.enable = true;
      };
    };

    users.users = lib.genAttrs (map (u: u.name) dusk.users)
      (name: { extraGroups = [ "docker" ]; });
  };
}
