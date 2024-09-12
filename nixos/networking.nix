args@{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ./firejail args) jail;
  inherit (lib) mkForce;
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
    networking = {
      nameservers = [
        "194.242.2.4" # mullvad ad + tracker + malware
        "194.242.2.3" # mullvad ad + tracker
        "194.242.2.2" # mullvad clear
      ];

      firewall.checkReversePath = "loose";
      iproute2.enable = true;

      interfaces.eno1.ipv4.routes = [
        {
          address = "104.244.42.0";
          prefixLength = 24;
          via = "10.72.234.244";
        }
      ];

      networkmanager = {
        enable = true;
        dns = mkForce "none";
      };

      wg-quick.interfaces.wg0.configFile = config.age.secrets."mullvad.age".path;
    };

    services = {
      resolved = {
        enable = true;
        fallbackDns = [ "" ];
      };

      tailscale.enable = true;
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];
  };
}
