{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos.server.transmission;
in
{
  config = lib.mkIf cfg.enable {
    services.transmission = {
      enable = true;

      user = config.dusk.username;
      webHome = pkgs.flood-for-transmission;

      settings = {
        download-dir = config.dusk.folders.downloads;
        watch-dir = "${config.dusk.folders.downloads}/_queue";

        rpc-bind-address = "0.0.0.0";
        rpc-bind-port = 9091;

        rpc-whitelist-enabled = false;
      };
    };

    users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
  };
}
