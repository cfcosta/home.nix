{ lib, pkgs, config, ... }:
with lib; {
  config = { environment.systemPackages = with pkgs; [ gpu-burn stress-ng ]; };
}
