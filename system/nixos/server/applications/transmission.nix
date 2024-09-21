{
  config,
  pkgs,
  ...
}:
let
  inherit (import ./lib.nix) defineService;

  cfg = config.dusk.system.nixos.server;
in
{
  imports = [
    (defineService rec {
      name = "transmission";
      port = 9091;

      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config = {
            services.transmission = {
              inherit (cfg.${name}) enable;

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
        };
    })

    (defineService rec {
      name = "bazarr";
      port = 6767;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
          inherit (cfg.${name}) enable;
        in
        {
          config.services.bazarr = {
            inherit (cfg.${name}) enable;

            openFirewall = false;
            user = config.dusk.username;

            group = "users";
          };
        };
    })
    (defineService rec {
      name = "lidarr";
      port = 8686;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config.services.lidarr = {
            inherit (cfg.${name}) enable;
            openFirewall = false;

            user = config.dusk.username;
            group = "users";

            dataDir = "${config.dusk.folders.downloads}/lidarr";
          };
        };
    })

    (defineService rec {
      name = "prowlarr";
      port = 9696;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config.services.prowlarr = {
            inherit (cfg.${name}) enable;
            openFirewall = false;
          };
        };
    })
    (defineService rec {
      name = "radarr";
      port = 7878;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config.services.radarr = {
            inherit (cfg.${name}) enable;
            openFirewall = false;

            user = config.dusk.username;
            group = "users";

            dataDir = "${config.dusk.folders.downloads}/radarr";
          };
        };
    })

    (defineService rec {
      name = "readarr";
      port = 8787;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config.services.readarr = {
            inherit (cfg.${name}) enable;
            openFirewall = false;

            user = config.dusk.username;
            group = "users";

            dataDir = "${config.dusk.folders.downloads}/readarr";
          };
        };
    })

    (defineService rec {
      name = "sonarr";
      port = 8989;
      config =
        { config, ... }:
        let
          cfg = config.dusk.system.nixos.server;
        in
        {
          config.services.sonarr = {
            inherit (cfg.${name}) enable;

            openFirewall = false;
            user = config.dusk.username;
            group = "users";
            dataDir = "${config.dusk.folders.downloads}/sonarr";
          };
        };
    })
  ];
}
