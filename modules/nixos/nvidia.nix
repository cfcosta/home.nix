{ lib, pkgs, config, ... }:
let cfg = config.dusk.nvidia;
in {
  options.dusk.nvidia.enable = lib.mkEnableOption "nvidia";

  config = lib.mkIf cfg.enable {
    hardware.nvidia.modesetting.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    virtualisation = lib.optionals config.dusk.containers.enable {
      docker.enableNvidia = true;
      podman.enableNvidia = true;
    };

    environment.variables = {
      GBM_BACKEND = "nvidia-drm";
      LIBVA_DRIVER_NAME = "nvidia";
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER = "vulkan";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";

      # Fix problems related to WebKit Applications on NVIDIA cards
      # See https://github.com/tauri-apps/tauri/issues/4315#issuecomment-1207755694
      # 
      # This should fix both Tauri applications, as well as Gnome Online Accounts login screen.
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    };
  };
}
