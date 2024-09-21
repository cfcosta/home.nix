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
        };

        systemd.services.flood = {
          wantedBy = [ "multi-user.target" ];
          wants = [ "rtorrent.service" ];
          after = [ "rtorrent.service" ];

          serviceConfig = {
            User = config.dusk.username;
            ExecStart = "${pkgs.flood}/bin/flood --auth none --port ${toString port} --rtsocket /run/rtorrent/rpc.sock";
          };
        };

        users.users.${config.dusk.username}.extraGroups = [ "rtorrent" ];
        users.groups.rtorrent = { };
      };
    };
}
