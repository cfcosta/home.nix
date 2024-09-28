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
        allowedTCPPorts = optionals config.services.eternal-terminal.enable [ 2022 ];
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
          sha256sum = "${pkgs.coreutils}/bin/sha256sum";
        in
        {
          text = ''
            current_hash=$(${sha256sum} /etc/dusk/networking/mullvad.conf 2>/dev/null | cut -d ' ' -f1)
            new_hash=$(${sha256sum} ${config.age.secrets.mullvad.path} | cut -d ' ' -f1)

            if [ "$current_hash" != "$new_hash" ]; then
              if ${nm} connection show mullvad &>/dev/null; then
                ${nm} connection delete mullvad
              fi

              ${nm} connection import type wireguard file ${config.age.secrets.mullvad.path}
              cp ${config.age.secrets.mullvad.path} /etc/dusk/networking/mullvad.conf
              printf 'installed/true' > /tmp/mullvad
            else
              printf 'skipped/true' > /tmp/mullvad
            fi
          '';
        };
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];
  };
}
