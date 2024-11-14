{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "deluge";
  port = 8112;

  config =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (builtins) toFile;
      inherit (lib) removePrefix;

      relativeMediaFolder = removePrefix "${config.dusk.folders.home}/" config.dusk.folders.media.root;

      cfg = config.dusk.system.nixos.server;
    in
    {
      config = {
        age.secrets.deluge = {
          file = ../../../secrets/deluge.age;
          owner = config.dusk.username;
          mode = "640";
        };

        home-manager.users.${config.dusk.username}.home.file = {
          "${relativeMediaFolder}/_watch/.keep".source = toFile ".keep" "";
          "${relativeMediaFolder}/_incomplete/.keep".source = toFile ".keep" "";
        };

        services.deluge = {
          inherit (cfg.${name}) enable;
          web.enable = true;
          dataDir = "${config.dusk.folders.media.data}/${name}";
          openFirewall = true;
          declarative = true;
          authFile = config.age.secrets.deluge.path;
          openFilesLimit = 65536;

          user = config.dusk.username;
          group = name;

          config = {
            download_location = "${config.dusk.folders.media.root}/_incomplete";
            move_completed_path = config.dusk.folders.media.root;
            move_completed = true;
            allow_remote = true;
            dont_count_slow_torrents = true;
            max_active_downloading = 32;
            max_active_limit = -1;
            max_active_seeding = -1;
            max_connections_global = -1;
            max_download_speed = -1;
            max_upload_speed = -1;

            # Listen on specific port
            random_port = false;
            listen_ports = [
              16880
              16880
            ];

            # Outgoing is random
            random_outgoing_ports = true;

            upnp = true;
            utpex = true;
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ name ];
      };
    };
}
