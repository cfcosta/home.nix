{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.gaming;
in {
  options = {
    devos.gaming.enable = mkEnableOption "gaming";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottles
      lutris
      mangohud
      retroarchFull
    ];

    hardware.opengl.enable = true;

    programs.steam.enable = true;
  };
}
