{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk;
in
{
  options.dusk.benchmarking.enable = mkEnableOption "Benchmarking and stress testing tools";

  config = mkIf cfg.benchmarking.enable {
    environment.systemPackages = with pkgs; [
      gpu-burn
      stress-ng
    ];
  };
}
