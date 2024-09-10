{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

    hardware = {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [ vaapiVdpau ];
      };

      nvidia = {
        gsp.enable = true;
        open = true;
        modesetting.enable = true;
      };

      nvidia-container-toolkit.enable = true;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
