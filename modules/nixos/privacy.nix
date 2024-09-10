{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.dusk.privacy;
in
{
  options.dusk.privacy.enable = mkEnableOption "privacy";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mullvad-vpn
      tor-browser
    ];
    services.mullvad-vpn.enable = true;
  };
}
