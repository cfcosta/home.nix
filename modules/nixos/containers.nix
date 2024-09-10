{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.dusk.containers;
in
{
  options = {
    dusk.containers.enable = mkEnableOption "containers";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker-compose
      ctop
    ];

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };

      podman = {
        enable = true;
        autoPrune.enable = true;
      };

      waydroid.enable = true;
      lxd.enable = true;
    };

    users.users.${config.dusk.user}.extraGroups = [
      "docker"
      "lxd"
    ];
  };
}
