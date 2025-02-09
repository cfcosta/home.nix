{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = config.dusk.system.nixos.virtualisation;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      optionals cfg.docker.enable [ docker-compose ] ++ optionals cfg.podman.enable [ podman-compose ];

    virtualisation = {
      docker = {
        inherit (cfg.docker) enable;
        autoPrune.enable = true;
      };

      libvirtd = { inherit (cfg.libvirt) enable; };

      podman = {
        inherit (cfg.podman) enable;

        autoPrune.enable = true;
      };
    };

    users.users.${config.dusk.username}.extraGroups =
      optionals cfg.libvirt.enable [ "libvirtd" ]
      ++ optionals cfg.podman.enable [ "podman" ]
      ++ optionals cfg.docker.enable [ "docker" ];
  };
}
