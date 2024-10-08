{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "sonarr";
  port = 8989;
  config =
    { config, ... }:
    {
      config.services.sonarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        openFirewall = false;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.media.data}/${name}";
      };
    };
}
