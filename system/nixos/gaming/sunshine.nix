{ config, lib, ... }:
let
  cfg = config.dusk.system.nixos.desktop;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    hardware.graphics.enable = true;

    services.sunshine = {
      enable = true;

      autoStart = true;
      capSysAdmin = true;
      openFirewall = false;

      settings = {
        qp = 20;
        min_log_level = "info";
        min_threads = 4;
        hevc_mode = 3;
        nvenc_preset = 3;
        sw_preset = "fast";
      };
    };
  };
}
