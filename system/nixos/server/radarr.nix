let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "radarr";
  port = 7878;
  config =
    { config, ... }:
    {
      config.services.radarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;
        openFirewall = false;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.media.data}/${name}";
      };
    };
}
