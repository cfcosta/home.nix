{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (import ./lib.nix) exposeHost;

  cfg = config.dusk.system.nixos.server;
  port = 3002;
in
{
  imports = [
    (exposeHost "transmission" port)
  ];

  config = mkIf cfg.transmission.enable {
    services.transmission = {
      enable = true;

      user = config.dusk.username;
      webHome = pkgs.flood-for-transmission;

      settings = {
        download-dir = config.dusk.folders.downloads;
        watch-dir = "${config.dusk.folders.downloads}/_queue";

        rpc-bind-address = "127.0.0.1";
        rpc-bind-port = port;

        rpc-whitelist-enabled = false;
      };
    };

    users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
  };
}
