{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.dusk.nvidia;
in
{
  options.dusk.nvidia = {
    enable = mkEnableOption "nvidia";
    powerLimit = mkOption {
      type = types.int;
      description = ''
        Power limit in watts, disabled if null.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nvtopPackages.nvidia ];

    hardware.nvidia = {
      gsp.enable = true;
      open = true;
      modesetting.enable = true;
    };
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [ vaapiVdpau ];
    };

    hardware.nvidia-container-toolkit.enable = true;

    environment.variables = {
      # Fix problems related to WebKit Applications on NVIDIA cards
      # See https://github.com/tauri-apps/tauri/issues/4315#issuecomment-1207755694
      # 
      # This should fix both Tauri applications, as well as Gnome Online Accounts login screen.
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    };
  };
}
