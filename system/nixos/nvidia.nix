{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos;
in
{
  config = lib.mkIf cfg.nvidia.enable {
    boot.kernelParams = [ "nvidia_drm.fbdev=1" ];

    environment = {
      sessionVariables = {
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };

      systemPackages = with pkgs; [ nvtopPackages.nvidia ];
    };

    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [ vaapiVdpau ];
      };

      nvidia = {
        gsp.enable = true;
        open = true;
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.beta;
      };

      nvidia-container-toolkit.enable = cfg.virtualisation.enable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
