{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkForce mkIf optionals;

  cfg = config.dusk.system.nixos.networking;
in
{
  config = mkIf cfg.enable {
    age.secrets = mkIf cfg.mullvad.enable {
      mullvad.file = ../../secrets/mullvad.age;
    };

    environment = {
      etc."dusk/networking/mullvad.conf".source = config.age.secrets.mullvad.path;

      systemPackages = [
        pkgs.dnsutils
      ];
    };

    networking = {
      inherit (cfg) nameservers;

      dhcpcd.enable = false;
      useDHCP = false;

      firewall = {
        checkReversePath = false;
        trustedInterfaces = optionals cfg.tailscale.enable [ "tailscale0" ];
      };

      iproute2.enable = true;

      networkmanager = {
        enable = true;
        dns = mkForce "none";
        insertNameservers = cfg.nameservers;
      };

      resolvconf.useLocalResolver = true;
    };

    services = {
      avahi =
        let
          net = config.dusk.system.nixos.networking;
        in
        {
          enable = true;

          allowInterfaces = [
            net.defaultNetworkInterface
          ] ++ optionals net.tailscale.enable [ "tailscale0" ];

          publish = {
            enable = true;

            domain = true;
            userServices = true;
            workstation = true;
          };

          nssmdns4 = true;
          nssmdns6 = true;
        };

      i2pd = mkIf cfg.i2p.enable {
        enable = true;
        address = "0.0.0.0";

        proto = {
          http.enable = true;
          httpProxy.enable = true;
          i2cp.enable = true;
          socksProxy.enable = true;
        };
      };

      resolved.enable = false;

      tailscale = {
        inherit (cfg.tailscale) enable;
      };
    };

    system.activationScripts = mkIf cfg.mullvad.enable {
      enable-mullvad =
        let
          nm = "${pkgs.networkmanager}/bin/nmcli";
        in
        {
          text = ''
            if ${nm} connection show mullvad &>/dev/null; then
              ${nm} connection delete mullvad
            fi

            ${nm} connection import type wireguard file /etc/dusk/networking/mullvad.conf
            printf 'installed/true' > /tmp/nullvad
          '';
        };
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];
  };
}
