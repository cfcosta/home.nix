{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;

  cfg = config.dusk.system.nixos.networking;
in
{
  config = mkIf cfg.enable {
    age.secrets = mkIf cfg.mullvad.enable {
      mullvad.file = ../../secrets/mullvad.age;
    };

    environment = {
      etc."dusk/networking/mullvad.conf".source = config.age.secrets.mullvad.path;

      systemPackages = with pkgs; [
        dnsutils
        inetutils
        mitmproxy
        tcpdump
      ];
    };

    networking = {
      firewall = {
        checkReversePath = false;
        trustedInterfaces = optionals cfg.tailscale.enable [ "tailscale0" ];
      };

      networkmanager.enable = true;
    };

    services = {
      avahi =
        let
          net = config.dusk.system.nixos.networking;
        in
        {
          enable = lib.mkForce false;

          allowInterfaces = [
            net.defaultNetworkInterface
          ] ++ optionals net.tailscale.enable [ "tailscale0" ];

          publish = {
            enable = lib.mkForce false;

            domain = lib.mkForce false;
            userServices = lib.mkForce false;
            workstation = lib.mkForce false;
          };

          nssmdns4 = lib.mkForce false;
          nssmdns6 = lib.mkForce false;
        };

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
