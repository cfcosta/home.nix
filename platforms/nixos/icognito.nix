{ lib, pkgs, config, ... }:
with lib; {
  config = {
    environment.systemPackages = with pkgs; [
      mullvad-vpn
      tor-browser-bundle-bin
    ];

    services.i2p.enable = true;
    services.mullvad-vpn.enable = true;
  };
}
