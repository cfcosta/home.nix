{ lib, pkgs, config, ... }:
with lib; {
  config = {
    environment.systemPackages = with pkgs; [ bottles lutris mangohud ];

    hardware.opengl.enable = true;
    programs.steam.enable = true;
  };
}
