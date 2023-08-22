{ config, lib, pkgs, ... }:
with lib;
let cfg = config.dusk.home.mutt;
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

    programs.bash.shellAliases = { mutt = "neomutt"; };
  };
}
