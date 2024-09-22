let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "bazarr";
  port = 6767;
  config =
    { config, ... }:
    {
      config.services.bazarr = {
        inherit (config.dusk.system.nixos.server.${name}) enable;

        user = config.dusk.username;
        group = "users";

        openFirewall = false;
      };
    };
}
