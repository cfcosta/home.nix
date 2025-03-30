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
    environment.systemPackages = with pkgs; optionals cfg.docker.enable [ docker-compose ];

    virtualisation = {
      docker = {
        inherit (cfg.docker) enable;
        autoPrune.enable = true;
      };

      libvirtd = { inherit (cfg.libvirt) enable; };
    };

    users.users.${config.dusk.username}.extraGroups =
      optionals cfg.libvirt.enable [ "libvirtd" ]
      ++ optionals cfg.docker.enable [ "docker" ];
  };
}
