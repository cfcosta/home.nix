{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.home.android;
in {
  options.dusk.home.android.enable =
    mkEnableOption "ADB and other android tools";

  config =
    mkIf cfg.enable { home.packages = with pkgs; [ android-tools scrcpy ]; };
}
