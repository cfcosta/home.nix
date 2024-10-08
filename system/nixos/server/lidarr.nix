{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "lidarr";
  port = 8686;
  config =
    { config, ... }:
    {
      config.services.lidarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        openFirewall = false;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.media.data}/${name}";
      };
    };
}
