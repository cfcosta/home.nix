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
    environment = {
      systemPackages = [
        pkgs.dnsutils
      ];

      etc."NetworkManager/system-connections/mullvad0.conf".source =
        config.age.secrets."mullvad.age".path;
    };

    networking = {
      nameservers = [
        "194.242.2.4" # mullvad ad + tracker + malware
        "194.242.2.3" # mullvad ad + tracker
        "194.242.2.2" # mullvad clear
      ];

      firewall.checkReversePath = false;
      iproute2.enable = true;

      networkmanager = {
        enable = true;
        dns = mkForce "none";
      };
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
