{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.dusk.virtualisation.enable = mkEnableOption "virtualisation";

  config = mkIf config.dusk.virtualisation.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      docker-compose
      podman-compose
      ctop
    ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };

      libvirtd.enable = true;
      lxd.enable = true;

      podman = {
        enable = true;
        autoPrune.enable = true;
      };

      waydroid.enable = true;
    };

    users.users.${config.dusk.user}.extraGroups = [
      "docker"
      "libvirtd"
      "lxd"
      "podman"
    ];
  };
}
