{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "transmission";
  port = 9091;

  config =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      inherit (builtins) readFile toFile;
      inherit (lib) removePrefix;

      relativeMediaFolder = removePrefix "${config.dusk.folders.home}/" config.dusk.folders.media.root;

      cfg = config.dusk.system.nixos.server;
    in
    {
      config = {
        home-manager.users.${config.dusk.username}.home.file = {
          "${relativeMediaFolder}/_watch/.keep".source = toFile ".keep" "";
          "${relativeMediaFolder}/_incomplete/.keep".source = toFile ".keep" "";
        };

        services.transmission = {
          inherit (cfg.${name}) enable;

          openFirewall = true;

          user = config.dusk.username;
          group = name;
          webHome = pkgs.flood-for-transmission;

          settings = {
            default-trackers = readFile ./trackers.txt;
            dht-enabled = true;
            download-dir = config.dusk.folders.media.root;
            encryption-required = false;
            incomplete-dir = "${config.dusk.folders.media.root}/_incomplete";
            message-level = 6;
            peer-port = 51413;
            pex-enable = true;
            rpc-bind-address = "0.0.0.0";
            rpc-bind-port = 9091;
            rpc-host-whitelist = [
              "transmission.${cfg.domain}"
              "localhost"
              "${config.dusk.system.hostname}"
            ];
            rpc-host-whitelist-enabled = true;
            rpc-whitelist = [
              "127.0.0.1"
              "10.0.*.*"
              "100.*.*.*"
            ];
            rpc-whitelist-enabled = true;
            watch-dir = "${config.dusk.folders.media.root}/_watch";
            watch-dir-enabled = true;
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
      };
    };
}
