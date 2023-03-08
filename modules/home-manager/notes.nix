{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.devos.home.notes;
  directory =
    builtins.replaceStrings [ "~" ] [ "/home/${config.devos.home.username}" ]
    cfg.directory;
  today = pkgs.writeShellApplication {
    name = "today";
    text = ''
      $EDITOR "${directory}/$(date +%Y-%m-%d).md"  
    '';
  };
  yesterday = pkgs.writeShellApplication {
    name = "yesterday";
    text = ''
      $EDITOR "${directory}/$(date -d "yesterday" +%Y-%m-%d).md"  
    '';
  };
  tomorrow = pkgs.writeShellApplication {
    name = "tomorrow";
    text = ''
      $EDITOR "${directory}/$(date -d "tomorrow" +%Y-%m-%d).md"  
    '';
  };
in {
  options.devos.home.notes = {
    enable = mkEnableOption "notes";

    directory = mkOption {
      type = types.str;
      default = "~/Notes";
      description = "Where the notes should be contained";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ today yesterday tomorrow ];
  };
}
