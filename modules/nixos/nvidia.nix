{
  lib,
  pkgs,
  config,
  ...
}:
lib.optionalAttrs config.dusk.nvidia.enable {
  environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ vaapiVdpau ];
      nvidia-container-toolkit.enable = true;
    };
    nvidia = {
      gsp.enable = true;
      open = true;
      modesetting.enable = true;
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];
}
