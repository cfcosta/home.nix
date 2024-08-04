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
    optionalAttrs
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

    hardware.nvidia.modesetting.enable = true;
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

    systemd = optionalAttrs (cfg.powerLimit != null) {
      timers.nvidia-power-limit = {
        timerConfig = {
          Unit = "nvidia-power-limit.service";
          OnBootSec = "5";
        };

        wantedBy = [ "timers.target" ];
      };

      services.nvidia-power-limit = {
        serviceConfig = {
          ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl ${toString cfg.powerLimit}";
          Type = "oneshot";
        };
      };
    };
  };
}
