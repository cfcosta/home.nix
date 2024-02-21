{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.gaming;
in {
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ bottles lutris mangohud ];

    hardware.opengl.enable = true;
    programs.steam.enable = true;
  };
}
