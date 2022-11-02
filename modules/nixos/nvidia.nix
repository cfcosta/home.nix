{ lib, pkgs, config, ... }:
let cfg = config.devos.nvidia;
in {
  options.devos.nvidia.enable = lib.mkEnableOption "nvidia";

  config = lib.mkIf cfg.enable {
    hardware.nvidia.modesetting.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
    };

    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER = "vulkan";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };
  };
}
