{ config, lib, ... }:
let
  inherit (lib) optionals;
  inherit (config.dusk.system.nixos) networking;

  externalInterface = networking.defaultNetworkInterface;
in
{
  imports = [
    ./applications
    ./dnsmasq.nix
    ./traefik.nix
  ];

  config = {
    boot.kernel.sysctl = {
      # if you use ipv4, this is all you need
      "net.ipv4.conf.all.forwarding" = true;

      # If you want to use it for ipv6
      "net.ipv6.conf.all.forwarding" = true;

      # source: https://github.com/mdlayher/homelab/blob/master/nixos/routnerr-2/configuration.nix#L52
      # By default, not automatically configure any IPv6 addresses.
      "net.ipv6.conf.all.accept_ra" = 0;
      "net.ipv6.conf.all.autoconf" = 0;
      "net.ipv6.conf.all.use_tempaddr" = 0;

      # On WAN, allow IPv6 autoconfiguration and tempory address use.
      "net.ipv6.conf.${externalInterface}.accept_ra" = 2;
      "net.ipv6.conf.${externalInterface}.autoconf" = 1;
    };

    networking = {
      nat = {
        inherit externalInterface;

        enable = true;
        enableIPv6 = true;

        internalInterfaces =
          [
            externalInterface
            "lo"
          ]
          ++ optionals networking.tailscale.enable [ "tailscale0" ]
          ++ optionals networking.mullvad.enable [ "mullvad0" ];
      };
    };

  };
}
