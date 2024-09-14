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
      optionals cfg.docker.enable [
        docker-compose
        ctop
      ]
      ++ optionals cfg.podman.enable [
        podman-compose
        ctop
      ]
      ++ optionals cfg.waydroid.enable [ waydroid-script ];

    virtualisation = {
      docker = {
        inherit (cfg.docker) enable;
        autoPrune.enable = true;
      };

      libvirtd = {
        inherit (cfg.libvirt) enable;
      };

      lxd.enable = cfg.libvirt.enable or cfg.waydroid.enable;

      podman = {
        inherit (cfg.podman) enable;

        autoPrune.enable = true;
      };

      waydroid = {
        inherit (cfg.waydroid) enable;
      };
    };

    users.users.${config.dusk.username}.extraGroups =
      optionals cfg.libvirt.enable [ "libvirtd" ]
      ++ optionals cfg.podman.enable [ "podman" ]
      ++ optionals cfg.waydroid.enable [ "lxd" ]
      ++ optionals cfg.docker.enable [ "docker" ];
  };
}
