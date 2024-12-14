{
  config,
  lib,
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
    };
  };
}
