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
    environment.systemPackages = with pkgs; [
      dnsutils
      ethtool
      inetutils
    ];

    networking = {
      firewall = {
        allowedTCPPorts = optionals config.services.syncthing.enable [ 22000 ];
        checkReversePath = false;
        trustedInterfaces = optionals cfg.tailscale.enable [ "tailscale0" ];
      };

      networkmanager.enable = true;
    };

    services = {
      avahi = {
        enable = true;

        settings = {
          server.allow-interfaces = if cfg.tailscale.enable then [ "tailscale0" ] else null;

          publish = {
            disable-publishing = false;
            disable-user-service-publishing = false;
            publish-addresses = true;
            publish-domain = true;
            publish-workstation = true;
          };
        };

        nssmdns4 = true;
        nssmdns6 = true;
      };

      tailscale = { inherit (cfg.tailscale) enable; };
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];

    # Work around fix for nm-online-service from stalling on WireGuard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.tailscaled.after = [ "systemd-networkd-wait-online.service" ];
  };
}
