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

      nvidia-container-toolkit.enable = cfg.virtualisation.enable;
    };

    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
