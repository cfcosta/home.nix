{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dusk.home.mutt;
  macLogFile = name:
    "${config.dusk.home.folders.home}/Library/Logs/${name}.log";
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
          OnCalendar = "*:0/2"; # Every 2 minutes
          # start immediately after computer is started:
          Persistent = "true";
        };

        Install = { WantedBy = [ "timers.target" ]; };
      };
    };
    darwin = {
      offlineimap = {
        enable = true;
        config = {
          ProgramArguments = [ "${pkgs.offlineimap}/bin/offlineimap" ];
          UserName = config.dusk.home.username;
          StartInterval = 120;
          StandardOutPath = macLogFile "offlineimap";
          StandardErrorPath = macLogFile "offlineimap";
        };
      };
    };
  };
  scripts = {
    openUrl = pkgs.writeShellScriptBin "open-url"
      (builtins.readFile ./mutt/mutt-open-url.sh);
  };
in {
  options.dusk.home.mutt.enable = mkEnableOption "mutt";

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [ abook msmtp neomutt notmuch offlineimap scripts.openUrl urlview ]
      ++ optionals pkgs.stdenv.isLinux [ mailutils ];

    home.file.".urlview".text = "COMMAND open-url ";
    home.file.".mailrc".text = ''
      set sendmail="${pkgs.msmtp}/bin/msmtp"
    '';
    home.file.".muttrc".text = builtins.readFile ./mutt/muttrc;
    home.file.".mutt/signature".text = ''
      Cheers,
      ${config.dusk.home.name}
    '';

    programs.bash.shellAliases.mutt = "neomutt";

    systemd.user = mkIf pkgs.stdenv.isLinux services.linux;
    launchd.agents = mkIf pkgs.stdenv.isDarwin services.darwin;
  };
}
