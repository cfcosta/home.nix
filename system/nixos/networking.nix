{
  config,
  lib,
  pkgs,
  ...
}:
let
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
  config = lib.mkIf config.dusk.system.nixos.networking.enable {
    environment.systemPackages = [
      pkgs.dnsutils
    ];

    networking = {
      inherit nameservers;

      dhcpcd.enable = false;
      useDHCP = false;

      firewall = {
        checkReversePath = false;
        trustedInterfaces = [ "tailscale0" ];
      };

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
        address = "10.0.0.0";

        proto = {
          http.enable = true;
          httpProxy.enable = true;
          i2cp.enable = true;
          socksProxy.enable = true;
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
