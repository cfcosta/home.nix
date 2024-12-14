{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.services.sunshine;

  prepare =
    {
      width,
      height,
      refreshRate,
    }:
    with pkgs;
    writeShellApplication {
      name = "hyprland-sunshine-prepare";
      text = ''

      '';
    };
in
{
  config = mkIf cfg.enable {
    services.sunshine.applications.apps = [
      {
        name = "Steam (Hyprland)";

        image-path = "${pkgs.sunshine}/assets/steam.png";

        cmd = "hyprctl dispatch exec ${pkgs.gamemode}/bin/gamemoderun ${pkgs.steam}/bin/steam steam://open/bigpicture";
        #
        # prep-cmd = [
        #   {
        #     do = "bash -c ${config.dusk.folders.home}/stream-sunshine.sh setup";
        #     undo = "bash -c ${config.dusk.folders.home}/stream-sunshine.sh teardown";
        #   }
        # ];

        exclude-global-prep-cmd = "false";
        auto-detach = "true";
      }
    ];
  };
}
