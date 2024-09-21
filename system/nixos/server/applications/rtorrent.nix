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
            throttle.max_uploads.set = 500
            throttle.max_uploads.global.set = 1000
            throttle.min_peers.normal.set = 20
            throttle.max_peers.normal.set = 200
            throttle.min_peers.seed.set = 30
            throttle.max_peers.seed.set = 100
            trackers.numwant.set = 160

            network.http.max_open.set = 800
            network.max_open_files.set = 6000
            network.max_open_sockets.set = 3000
          '';
        };

        systemd.services = {
          flood = {
            wantedBy = [ "multi-user.target" ];
            wants = [ "rtorrent.service" ];
            after = [ "rtorrent.service" ];

            serviceConfig = {
              User = config.dusk.username;
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
