{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.dusk.system.nixos.nvidia.enable {
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

      nvidia-container-toolkit.enable = config.dusk.system.nixos.virtualisation.enable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
