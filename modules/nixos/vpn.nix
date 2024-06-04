{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.vpn;
in
{
  options.dusk.vpn.enable = mkEnableOption "vpn";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ mullvad-vpn ];
    services.mullvad-vpn.enable = true;
  };
}
