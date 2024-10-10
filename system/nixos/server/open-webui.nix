{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "chat";
  port = 9002;
  config =
    { config, ... }:
    {
      config.services.open-webui = {
        inherit (config.dusk.system.nixos.server.${name}) enable;
        inherit port;

        openFirewall = false;
      };
    };
}
