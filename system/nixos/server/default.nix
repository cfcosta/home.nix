{ config, lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.dusk.folders.media = {
    root = mkOption {
      type = types.str;
      default = "${config.dusk.folders.downloads}/Media";
      description = "The root folder for downloaded media, like books, movies, TV shows.";
    };

    data = mkOption {
      type = types.str;
      default = "${config.dusk.folders.media.root}/_data";
      description = "The folder where download aplications will keep their data (for easy back-up).";
    };
  };

  imports = [
    ./bazarr.nix
    ./deluge.nix
    ./gitea.nix
    ./jellyfin.nix
    ./lidarr.nix
    ./prowlarr.nix
    ./radarr.nix
    ./readarr.nix
    ./rtorrent.nix
    ./sonarr.nix
    ./traefik.nix
    ./transmission.nix
  ];
}
