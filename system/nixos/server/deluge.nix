{ dusk-lib, ... }:
dusk-lib.defineService rec {
  name = "deluge";
  port = 8112;

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (builtins) toFile;
      inherit (lib) mkIf removePrefix;

      relativeMediaFolder = removePrefix "${config.dusk.folders.home}/" config.dusk.folders.media.root;

      cfg = config.dusk.system.nixos.server;
      package = pkgs.deluge.overrideAttrs (old: {
        postPatch = ''
          ${old.postPatch or ""}
          sed -i '122,130c\        return True' deluge/ui/web/auth.py
        '';
      });
    in
    {
      config = mkIf cfg.enable {
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
          inherit package;

          web.enable = true;
          openFirewall = true;
          declarative = true;
          authFile = config.age.secrets.deluge.path;
          openFilesLimit = 65536;

          user = config.dusk.username;
          group = name;

          config = {
            download_location = "${config.dusk.folders.media.root}/_incomplete";
            move_completed_path = "${config.dusk.folders.media.root}/_complete";
            move_completed = true;
            allow_remote = true;
            dont_count_slow_torrents = true;
            max_active_downloading = 64;
            max_active_limit = -1;
            max_active_seeding = -1;
            max_connections_global = -1;
            max_download_speed = -1;
            max_upload_speed = -1;
            random_port = true;
            random_outgoing_ports = true;
            upnp = true;
            utpex = true;
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ name ];
      };
    };
}
