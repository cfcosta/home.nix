{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.nvidia;
in {
  options = {
    devos.nvidia.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable the NVIDIA driver
      '';
    };
    devos.nvidia.wayland = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable wayland support for the NVIDIA driver
      '';
    };
  };

  config = mkIf cfg.enable {
    hardware.nvidia.modesetting.enable = cfg.wayland;
    services.xserver.videoDrivers = [ "nvidia" ];
    environment.variables.GBM_BACKEND = lib.optionals cfg.wayland "nvidia-drm";
  };
}
