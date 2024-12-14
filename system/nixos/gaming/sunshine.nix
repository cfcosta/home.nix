{
  config,
  lib,
  pkgs,
  ...
}:
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
      openFirewall = true;

      applications = {
        apps = [
          {
            name = "Desktop";
            image-path = "${pkgs.sunshine}/assets/desktop.png";
            exclude-global-prep-cmd = "false";
            auto-detach = "true";
          }
        ];
      };
    };
  };
}
