args@{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ./firejail args) jail;
  inherit (lib) mkForce;

  nameservers = [
    "127.0.0.1"
    "::1"
    "194.242.2.4" # mullvad ad + tracker + malware
    "194.242.2.3" # mullvad ad + tracker
    "194.242.2.2" # mullvad clear
  ];
in
{
  imports = [
    (jail {
      name = "tor-browser";
      executable = "${pkgs.tor-browser}/bin/tor-browser";
      profile = "${pkgs.firejail}/etc/firejail/tor-browser.profile";
      desktop = "${pkgs.tor-browser}/share/applications/torbrowser.desktop";
    })
    (jail {
      name = "mullvad-browser";
      executable = "${pkgs.mullvad-browser}/bin/mullvad-browser";
      profile = "${pkgs.firejail}/etc/firejail/google-chrome.profile";
      desktop = "${pkgs.mullvad-browser}/share/applications/mullvad-browser.desktop";
    })
  ];

  config = {
    environment.systemPackages = [
      pkgs.dnsutils
    ];

    networking = {
      inherit nameservers;

      dhcpcd.enable = false;
      firewall.checkReversePath = false;
      iproute2.enable = true;

      networkmanager = {
        enable = true;
        dns = mkForce "none";
        insertNameservers = nameservers;
      };

      resolvconf.useLocalResolver = true;
    };

    services = {
      dnscrypt-proxy2.enable = true;

      i2pd = {
        enable = true;
        address = "127.0.0.1";

        proto = {
          http.enable = true;
          socksProxy.enable = true;
          httpProxy.enable = true;
        };
      };

      resolved.enable = false;
      tailscale.enable = true;
    };

    system.activationScripts = {
      enable-mullvad = {
        deps = [ ];
        text =
          let
            nm = "${pkgs.networkmanager}/bin/nmcli";
          in
          ''
            if $(${nm} connection | grep mullvad0 &>/dev/null); then
              printf 'skip/true' > /tmp/mullvad
            else
              ${nm} connection import type wireguard file ${config.age.secrets."mullvad.age".path}

              printf 'installed/true' > /tmp/nullvad
            fi
          '';
      };
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];
  };
}
