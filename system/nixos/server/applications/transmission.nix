let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "transmission";
  port = 9091;

  config =
    { config, pkgs, ... }:
    {
      config = {
        services.transmission = {
          inherit (config.dusk.system.nixos.server.${name}) enable;

          openFirewall = false;

          user = config.dusk.username;
          webHome = pkgs.flood-for-transmission;

          settings = {
            download-dir = "${config.dusk.folders.downloads}/Media";
            watch-dir = "${config.dusk.folders.downloads}/Media/_queue";

            encryption-required = true;
            rpc-bind-address = "127.0.0.1";
            rpc-bind-port = 9091;
            rpc-host-whitelist = "transmission.${config.dusk.system.nixos.server.domain}";
            rpc-whitelist-enabled = true;
            rpc-whitelist = "10.0.0.*,100.*.*.*";
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
      };
    };
}
