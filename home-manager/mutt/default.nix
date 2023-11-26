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
          Label = "offlineimap";
          ProgramArguments = [ "${pkgs.offlineimap}/bin/offlineimap" ];
          UserName = config.dusk.home.username;
          StartInterval = 120;
          StandardOutPath = macLogFile "offlineimap";
          StandardErrorPath = macLogFile "offlineimap";
        };
      };
    };
  };
  scripts = [
    (pkgs.writeShellScriptBin "mutt-open-url"
      (builtins.readFile ./mutt-open-url.sh))
    (pkgs.writeShellScriptBin "mutt-add-todoist"
      (builtins.readFile ./mutt-add-todoist.sh))
  ];
in {
  options.dusk.home.mutt.enable = mkEnableOption "mutt";

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [ abook msmtp neomutt notmuch offlineimap urlview todoist-cli ] ++ scripts
      ++ optionals pkgs.stdenv.isLinux [ mailutils ];

    home.file.".urlview".text = "COMMAND mutt-open-url ";
    home.file.".mailrc".text = ''
      set sendmail="${pkgs.msmtp}/bin/msmtp"
    '';
    home.file.".muttrc".text = builtins.readFile ./muttrc;
    home.file.".mutt/signature".text = ''
      Cheers,
      ${config.dusk.home.name}
    '';
    home.file.".mutt/theme.mutt".text = builtins.readFile ./theme.mutt;

    programs.bash.shellAliases.mutt = "neomutt";

    systemd.user = mkIf pkgs.stdenv.isLinux services.linux;
    launchd.agents = mkIf pkgs.stdenv.isDarwin services.darwin;
  };
}
