{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.server;

  hostConfig = (import ./lib.nix).exposeHost {
    name = "transmission";
    domain = "transmission.${cfg.domain}";
    port = config.services.transmissions.settings.rpc-bind-port;
  };
in
{
  config =
    mkIf cfg.transmission.enable {
      services.transmission = {

        enable = true;

        user = config.dusk.username;
        webHome = pkgs.flood-for-transmission;

        settings = {
          download-dir = config.dusk.folders.downloads;
          watch-dir = "${config.dusk.folders.downloads}/_queue";

          rpc-bind-address = "0.0.0.0";
          rpc-bind-port = 10003;

          rpc-whitelist-enabled = false;
        };
      };

      users.users.${config.dusk.username}.extraGroups = [ "transmission" ];
    }
    // hostConfig;
}
