let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "rtorrent";
  port = 10001;

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkOption types;
    in
    {
      options.dusk.folders.media.watch = mkOption {
        type = types.str;
        default = "${config.dusk.folders.media.root}/_watch";

        description = "A folder rtorrent will watch to find new torrents to download.";
      };

      config = {
        environment.systemPackages = [
          pkgs.rtorrent
        ];

        services.rtorrent = {
          inherit (config.dusk.system.nixos.server.${name}) enable;

          package = pkgs.rtorrent;

          openFirewall = false;
          port = 10002;

          user = config.dusk.username;
          group = "rtorrent";

          dataDir = "${config.dusk.folders.media.data}/${name}";
          downloadDir = config.dusk.folders.media.root;

          configText = ''
            dht = on

            protocol.pex.set = yes

            trackers.numwant.set = 160
            trackers.use_udp.set = yes

            # Disable when diskspace is low
            schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))

            # Add more DHT nodes
            schedule2 = dht_node_1, 5, 0, "dht.add_node=router.utorrent.com:6881"
            schedule2 = dht_node_2, 5, 0, "dht.add_node=dht.transmissionbt.com:6881"
            schedule2 = dht_node_3, 5, 0, "dht.add_node=router.bitcomet.com:6881"
            schedule2 = dht_node_4, 5, 0, "dht.add_node=dht.aelitis.com:6881"

            schedule = watch_directory,5,5,load_start=${config.dusk.folders.media.watch}/*.torrent

            # Read trackers from file and add them to all torrents
            method.insert = tracker_list, private|const|string, (cat,"${./transmission/trackers.txt}")
            method.insert = tracker_insert, private|simple, "d.tracker.insert=\"\$argument.0=\",d.save_full_session="
            method.insert = tracker_insert_from_file, private|simple, "branch=(not, (system.file.exists, (argument.0))), ((print, \"No trackers file: \", (argument.0))), ((import, (argument.0)))"
            method.set_key = event.download.inserted_new, add_trackers, "tracker_insert_from_file=$tracker_list"
          '';
        };

        systemd.services.flood = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "rtorrent.service" ];
          after = [ "rtorrent.service" ];

          serviceConfig = {
            User = config.dusk.username;
            Group = "rtorrent";
            ExecStart = "${pkgs.flood}/bin/flood --auth none --port ${toString port} --rtsocket ${config.services.rtorrent.rpcSocket}";
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "rtorrent" ];
        users.groups.rtorrent = { };
      };
    };
}
