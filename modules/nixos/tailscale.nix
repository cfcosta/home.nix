{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.tailscale;
  certDir = "/var/lib/dusk/certs";

  refresh-cert = pkgs.writeShellApplication {
    name = "tailscale-refresh-cert";
    runtimeInputs = with pkgs; [
      tailscale
      gnused
      coreutils
    ];
    text = ''
      DOMAIN="$(tailscale status | grep "${config.networking.hostName}" | sed "s/\s\+/ /g" | cut -f 3 -d" ")"

      echo "Setting up certificate for domain $DOMAIN..."
      tailscale cert --cert-file ${certDir}/tailscale.crt --key-file ${certDir}/tailscale.key "$DOMAIN"

      chown nginx:nginx ${certDir}/tailscale.crt ${certDir}/tailscale.key
      chmod 600 ${certDir}/tailscale.crt ${certDir}/tailscale.key
    '';
  };
in
{
  options.dusk.tailscale.enable = mkEnableOption "tailscale";

  config = mkIf cfg.enable {
    services.tailscale.enable = true;

    systemd = {
      timers.tailscale-refresh-cert = {
        timerConfig = {
          Unit = "tailscale-cert.service";

          OnBootSec = "5s";
          OnCalendar = "daily";
          Persistent = true;
        };

        wantedBy = [ "timers.target" ];
      };

      services.tailscale-refresh-cert = {
        serviceConfig = {
          Type = "oneshot";

          ExecStartPre = [
            "+${pkgs.coreutils}/bin/mkdir -p ${certDir}"
            "+${pkgs.coreutils}/bin/chmod 755 ${certDir}"
          ];

          ExecStart = "${refresh-cert}/bin/tailscale-refresh-cert";
          Restart = "on-failure";
        };

        requires = [ "tailscaled.service" ];
      };
    };

    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
  };
}
