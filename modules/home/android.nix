{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.home.android;

  scrcpy =
    if pkgs.stdenv.isLinux then (pkgs.scrcpy.override { ffmpeg = pkgs.ffmpeg-full; }) else pkgs.scrcpy;

  android-stream-to-camera = pkgs.writeShellScriptBin "android-stream-to-camera" ''
    DEVICE="$(basename $(echo /sys/devices/virtual/video4linux/video?))"
    ${scrcpy}/bin/scrcpy --v4l2-sink="/dev/$DEVICE" --no-video-playback --no-audio $@
  '';
in
{
  options.dusk.home.android.enable = mkEnableOption "ADB and other android tools";

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.android-tools
      scrcpy
    ] ++ optionals pkgs.stdenv.isLinux [ android-stream-to-camera ];
  };
}
