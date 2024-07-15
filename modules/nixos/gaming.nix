{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.dusk.gaming;
  inherit (lib) mkEnableOption mkIf;
in
{
  options = {
    dusk.gaming.enable = mkEnableOption "gaming";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mangohud ];
    hardware.graphics.enable = true;
    programs.steam.enable = true;
  };
}
