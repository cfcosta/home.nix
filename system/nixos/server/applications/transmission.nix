{ config, pkgs, ... }:
let
  inherit (import ./lib.nix) defineService;
  cfg = config.dusk.system.nixos.server;
in
{
  imports = [
    (defineService {
      name = "transmission";
      port = 9091;

      config = {
        services.transmission = {
          enable = true;
          openFirewall = false;

          user = config.dusk.username;
          webHome = pkgs.flood-for-transmission;

          settings = {
            download-dir = config.dusk.folders.downloads;
            watch-dir = "${config.dusk.folders.downloads}/_queue";

            encryption-required = true;
            rpc-bind-address = "127.0.0.1";
            rpc-bind-port = 9091;
            rpc-host-whitelist = "transmission.${cfg.domain}";
            rpc-whitelist-enabled = true;
            rpc-whitelist = "10.0.0.*,100.*.*.*";
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
      };
    })

    (defineService {
      name = "bazarr";
      port = 6767;
      config.services.bazarr = {
        enable = true;
        openFirewall = false;

        user = config.dusk.username;
        group = "users";
      };
    })
    (defineService {
      name = "lidarr";
      port = 8686;
      config.services.lidarr = {
        enable = true;
        openFirewall = false;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.downloads}/lidarr";
      };
    })

    (defineService {
      name = "prowlarr";
      port = 9696;
      config.services.prowlarr = {
        enable = true;
        openFirewall = false;
      };
    })

    (defineService {
      name = "radarr";
      port = 7878;
      config.services.radarr = {
        enable = true;
        openFirewall = false;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.downloads}/radarr";
      };
    })

    (defineService {
      name = "readarr";
      port = 8787;
      config.services.readarr = {
        enable = true;

        user = config.dusk.username;
        group = "users";

        dataDir = "${config.dusk.folders.downloads}/readarr";
      };
    })

    (defineService {
      name = "sonarr";
      port = 8989;
      config.services.sonarr = {
        enable = true;
        openFirewall = false;
        user = config.dusk.username;
        group = "users";
        dataDir = "${config.dusk.folders.downloads}/sonarr";
      };
    })
  ];
}
