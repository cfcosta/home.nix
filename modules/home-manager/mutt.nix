{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dusk.home.mutt;
  services = rec {
    linux = {
      services.offlineimap = {
        Unit.Description = "Fetch email inboxes";
        Service.ExecStart =
          "${pkgs.offlineimap}/bin/offlineimap -u syslog -o -1";
      };

      timers.offlineimap = {
        Unit.Description = "Timer for fetching email inboxes";

        Timer = {
          Unit = "offlineimap.service";
          OnCalendar = "*:0/3"; # Every 3 minutes
          # start immediately after computer is started:
          Persistent = "true";
        };

        Install = { WantedBy = [ "timers.target" ]; };
      };
    };
    darwin = { };
  };
in {
  options = {
    dusk.home.mutt = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [ offlineimap neomutt msmtp ]
      ++ optionals pkgs.stdenv.isLinux [ mailutils ];

    home.file.".mailrc".text = ''
      set sendmail="${pkgs.msmtp}/bin/msmtp"
    '';
    home.file.".muttrc".text = builtins.readFile ./mutt/muttrc;

    programs.bash.shellAliases.mutt = "neomutt";

    systemd.user = mkIf pkgs.stdenv.isLinux services.linux;
  };
}
