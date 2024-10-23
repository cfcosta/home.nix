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
        package = config.boot.kernelPackages.nvidiaPackages.beta;
        open = false;
        gsp.enable = true;
        forceFullCompositionPipeline = false;
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
      };

      nvidia-container-toolkit.enable = cfg.virtualisation.enable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
