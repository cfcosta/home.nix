{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.stdenv) isLinux;
  cfg = config.protoss.hardware.nvidia;
in
{
  options.protoss.hardware.nvidia = {
    enable = mkOption {
      type = types.bool;
      default = isLinux;
      description = "Enable NVIDIA hardware support.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

    hardware.nvidia.modesetting.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [ vaapiVdpau ];
    };

    virtualisation.docker.enableNvidia = config.protoss.server.docker.enable;
    hardware.nvidia-container-toolkit.enable = config.protoss.server.docker.enable;

    environment.variables = {
      # Fix problems related to WebKit Applications on NVIDIA cards
      # See https://github.com/tauri-apps/tauri/issues/4315#issuecomment-1207755694
      # This should fix both Tauri applications, as well as Gnome Online Accounts login screen.
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    };
  };
}
