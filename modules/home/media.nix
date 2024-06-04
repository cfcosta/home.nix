{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dusk.home;
in
{
  options.dusk.home.media.enable = mkEnableOption "media";

  config = mkIf cfg.media.enable {
    home.packages = with pkgs; [
      ffmpeg
      python311Packages.yt-dlp
    ];
  };
}
