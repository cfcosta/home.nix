{ config, pkgs, lib, ... }:
with lib;
let cfg = config.dusk.home.crypto;
in {
  options.dusk.home.crypto.enable = mkEnableOption "crypto support";
  config = mkIf cfg.enable { home.packages = with pkgs; [ aiken ]; };
}
