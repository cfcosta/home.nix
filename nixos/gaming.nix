{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.gaming;
in {
  options = { dusk.gaming.enable = mkEnableOption "gaming"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ bottles lutris mangohud ];

    hardware.opengl.enable = true;
    programs.steam.enable = true;
  };
}
