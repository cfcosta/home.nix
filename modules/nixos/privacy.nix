{
  lib,
  pkgs,
  config,
  ...
}:
lib.optionalAttrs config.dusk.privacy.enable {
  environment.systemPackages = with pkgs; [
    mullvad-vpn
    tor-browser
  ];
  services.mullvad-vpn.enable = true;
}
