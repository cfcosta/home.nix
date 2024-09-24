{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "jellyfin";
  port = 8096;
  config =
    { config, ... }:
    {
      config.services.jellyfin = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        user = config.dusk.username;
        group = "users";

        openFirewall = false;
      };
    };
}
