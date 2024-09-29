{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) readFile;
  inherit (lib) mkIf optionals;

  cfg = config.dusk.system.nixos.networking;
in
{
  config = mkIf cfg.enable {
    age.secrets = mkIf cfg.mullvad.enable {
      mullvad.file = ../../secrets/mullvad.age;
    };

    environment = {
      systemPackages = with pkgs; [
        dnsutils
        inetutils
        mitmproxy
        tcpdump
        tshark
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
            ${readFile ../../scripts/bash-lib.sh}

            set -e

            _info "Installing Mullvad Connection into NetworkManager"

            mkdir -p /etc/dusk/networking

            if [ -f /etc/dusk/networking/mullvad.conf ]; then
              CURRENT_HASH=$(${sha256sum} /etc/dusk/networking/mullvad.conf 2>/dev/null | cut -d ' ' -f1)
              NEW_HASH=$(${sha256sum} ${config.age.secrets.mullvad.path} | cut -d ' ' -f1)

              _info "Found old connection with hash: $(_blue "$CURRENT_HASH")"
              _debug "New connection hash: $(_blue "$NEW_HASH")"

              if [ "$CURRENT_HASH" == "$NEW_HASH" ] || ! ; then
                _info "Mullvad is already installed and up to date, nothing else to do."
                printf 'skipped/true' > /tmp/mullvad

                exit 0
              fi

              _info "Hashes mismatched, removing old connection."
              ${nm} connection delete mullvad || true
            fi

            cp ${config.age.secrets.mullvad.path} /etc/dusk/networking/mullvad.conf 2>/dev/null
            ${nm} connection import type wireguard file /etc/dusk/networking/mullvad.conf

            printf 'installed/true' > /tmp/mullvad

            _info "Done, installed new Mullvad connection."
          '';
        };
    };

    users.users.${config.dusk.username}.extraGroups = [
      "networkmanager"
      "wireshark"
    ];
  };
}
