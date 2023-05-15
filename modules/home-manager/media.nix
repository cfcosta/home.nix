{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home;
in {
  options.devos.home.media.enable = mkEnableOption "media";

  config = mkIf cfg.media.enable {
    home.packages = with pkgs; [ python310Packages.yt-dlp ];
  };
}
