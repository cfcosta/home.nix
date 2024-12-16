{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "navidrome";
  port = 4533;
  config =
    { config, ... }:
    {
      config.services.navidrome = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        user = config.dusk.username;
        group = "users";

        openFirewall = false;

        settings = {
          MusicFolder = "/media/Music2";

          # Server settings
          Address = "127.0.0.1";
          Port = port;
          BaseUrl = "https://${name}.${config.dusk.system.nixos.server.domain}";
          UILoginBackground = "";

          # Scanning settings
          ScanSchedule = "@every 10m";
          AutoImportPlaylists = true;

          # Library settings
          DefaultTheme = "Dark";
          DefaultLanguage = "en";
          EnableGravatar = true;
          EnableStarRating = true;
          EnableFavourites = true;

          # Playback settings
          EnableDownloads = true;
          EnableCoverAnimation = true;

          # Security settings
          AuthRequestLimit = 5;
          SessionTimeout = "24h";
          EnableSharing = true;

          ArtistArtPriority = "artist.*, album/artist.*, external";
        };
      };
    };
}
