{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dusk.system.nixos.gaming;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    boot.kernel.sysctl."vm.max_map_count" = 1048576;

    environment.systemPackages = with pkgs; [
      gamemode
    ];

    hardware = {
      graphics.enable = true;

      # Support for Xbox One Controllers
      xone.enable = true;
    };

    home-manager.users.${config.dusk.username}.xdg.configFile."gamemode.ini".text = ''
      [general]
      softrealtime=on

      [cpu]
      pin_cores=no
    '';

    programs = {
      gamescope = {
        enable = true;
        capSysNice = true;
      };

      steam = {
        enable = true;

        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
      };
    };

    users.users.${config.dusk.username}.extraGroups = [ "gamemode" ];
  };
}
