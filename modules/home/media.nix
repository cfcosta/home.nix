{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home;
in {
  config = mkIf cfg.media.enable {
    home.packages = with pkgs; [ python311Packages.yt-dlp ffmpeg ];
  };
}
