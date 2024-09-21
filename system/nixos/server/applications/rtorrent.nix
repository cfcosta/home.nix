let
  inherit (import ./lib.nix) defineService;
in
defineService rec {
  name = "rtorrent";
  port = 10001;

  config =
    { config, pkgs, ... }:
    {
      config = {
        environment.systemPackages = [
          pkgs.jesec-rtorrent
        ];

        services.rtorrent = {
          inherit (config.dusk.system.nixos.server.${name}) enable;

          package = pkgs.jesec-rtorrent;

          openFirewall = false;
          port = 10002;

          user = config.dusk.username;
          group = "rtorrent";

          dataDir = "${config.dusk.folders.downloads}/Media/_data/${name}";
          downloadDir = "${config.dusk.folders.downloads}/Media";

          configText = ''
            dht = on

            network.http.max_open.set = 800
            network.max_open_files.set = 6000
            network.max_open_sockets.set = 3000

            protocol.pex.set = yes

            throttle.max_peers.normal.set = 200
            throttle.max_peers.seed.set = 100
            throttle.max_uploads.global.set = 1000
            throttle.max_uploads.set = 500
            throttle.min_peers.normal.set = 20
            throttle.min_peers.seed.set = 30

            trackers.numwant.set = 160
            trackers.use_udp.set = yes

            # Disable when diskspace is low
            schedule2 = monitor_diskspace, 15, 60, ((close_low_diskspace, 1000M))

            schedule2 = dht_node_1, 5, 0, "dht.add_node=router.utorrent.com:6881"
            schedule2 = dht_node_2, 5, 0, "dht.add_node=dht.transmissionbt.com:6881"
            schedule2 = dht_node_3, 5, 0, "dht.add_node=router.bitcomet.com:6881"
            schedule2 = dht_node_4, 5, 0, "dht.add_node=dht.aelitis.com:6881"
          '';
        };

        systemd.services = {
          flood = {
            wantedBy = [ "multi-user.target" ];
            wants = [ "rtorrent.service" ];
            after = [ "rtorrent.service" ];

            serviceConfig = {
              User = config.dusk.username;
              Group = "rtorrent";
              ExecStart = "${pkgs.flood}/bin/flood --auth none --port ${toString port} --rtsocket /run/rtorrent/rpc.sock";
            };
          };

          rtorrent.serviceConfig = {
            LimitNOFILE = 16384;
            LimitNPROC = 16384;
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "rtorrent" ];
        users.groups.rtorrent = { };
      };
    };
}
