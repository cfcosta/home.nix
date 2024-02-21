{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk;
in {
  config = mkIf cfg.benchmarking.enable {
    environment.systemPackages = with pkgs; [ gpu-burn stress-ng ];
  };
}
