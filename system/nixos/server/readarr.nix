{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "readarr";
  port = 8787;
  config =
    { config, ... }:
    {
      config.services.readarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.media.data}/${name}";
      };
    };
}
