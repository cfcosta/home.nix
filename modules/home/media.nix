{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.dusk.home;
in
{
  options.dusk.home.media.enable = mkEnableOption "media";

  config = mkIf cfg.media.enable {
    home.packages = with pkgs; [
      ffmpeg
      python312Packages.yt-dlp
      streamlink
    ];
  };
}
