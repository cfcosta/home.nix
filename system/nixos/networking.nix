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
      avahi =
        let
          net = config.dusk.system.nixos.networking;
        in
        {
          enable = true;

          allowInterfaces = optionals net.tailscale.enable [ "tailscale0" ];

          publish = {
            enable = true;

            domain = true;
            userServices = true;
            workstation = true;
          };

          nssmdns4 = true;
          nssmdns6 = true;
        };

      tailscale = { inherit (cfg.tailscale) enable; };
    };

    users.users.${config.dusk.username}.extraGroups = [ "networkmanager" ];
  };
}
