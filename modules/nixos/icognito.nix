{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.icognito;
in
{
  options.dusk.icognito.enable = mkEnableOption "icognito";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mullvad-vpn
      tor-browser-bundle-bin
    ];

    services.i2p.enable = true;
    services.mullvad-vpn.enable = true;
  };
}
