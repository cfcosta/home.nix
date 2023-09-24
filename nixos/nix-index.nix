{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.elss.nix-index-db-update;
  nix-index-db-update = pkgs.writeShellScript "nix-index-db-update" ''
    set -euo pipefail

    root=/var/db/nix-index
    filename="index-x86_64-$(${pkgs.coreutils}/bin/uname | ${pkgs.coreutils}/bin/tr A-Z a-z)"
    ${pkgs.wget}/bin/wget -q -N https://github.com/Mic92/nix-index-database/releases/latest/download/$filename -O $root/files
  '';
in {
  systemd = {
    services.nix-index-db-update = {
      description = "Update nix-index database";

      serviceConfig = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        ExecStartPre = [
          "+${pkgs.coreutils}/bin/mkdir -p /var/db/nix-index/"
          "+${pkgs.coreutils}/bin/chown nobody:nogroup /var/db/nix-index/"
        ];
        ExecStart = toString nix-index-db-update;
        User = "nobody";
        Group = "nogroup";

        # If it fails, retry 5 times within 10 minutes
        Restart = "on-failure";
        StartLimitBurst = "5";
        StartLimitIntervalSec = "600";
      };

      wantedBy = [ "multi-user.target" ];
    };

    timers.nix-index-db-update = {
      description = "nix-index database periodic update";

      timerConfig = {
        Unit = "nix-index-db-update.service";
        OnCalendar = "daily";
        OnBootSec = "30s";
        Persistent = true;
      };

      wantedBy = [ "timers.target" ];
    };
  };
}
