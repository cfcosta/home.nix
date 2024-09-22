let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "prowlarr";
  port = 9696;
  config =
    { config, ... }:
    {
      config.services.prowlarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        openFirewall = false;
      };
    };
}
