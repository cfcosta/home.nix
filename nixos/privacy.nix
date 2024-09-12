args@{ pkgs, ... }:
let
  inherit (import ./firejail args) jail;
in
{
  imports = [
    (jail {
      name = "tor-browser";
      executable = "${pkgs.tor-browser}/bin/tor-browser";
      profile = "${pkgs.firejail}/etc/firejail/tor-browser.profile";
      desktop = "${pkgs.tor-browser}/share/applications/torbrowser.desktop";
    })
  ];

  config = {
    services.tor = {
      enable = true;
      openFirewall = true;

      settings = {
        TransPort = [ 9040 ];
        DNSPort = 5353;
        VirtualAddrNetworkIPv4 = "172.30.0.0/16";
      };
    };
  };
}
