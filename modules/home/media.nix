{
  config,
  lib,
  pkgs,
  ...
}:
lib.optionalAttrs config.dusk.media.enable {
  home.packages = with pkgs; [
    ffmpeg
    python312Packages.yt-dlp
    streamlink
  ];
}
