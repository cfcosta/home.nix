{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.devos.home;
  directory = builtins.replaceStrings [ "~" ] [ "$HOME" ] cfg.folders.notes;
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
  next-week = pkgs.writeShellApplication {
    name = "next-week";
    text = ''
      $EDITOR "${directory}/$(date -d "next Monday" +%Y-%m-%d).md"  
    '';
  };
in {
  options.devos.home = {
    notes.enable = mkEnableOption "notes";

    folders.notes = mkOption {
      type = types.str;
      default = "~/Notes";
    };
  };

  config = mkIf cfg.notes.enable {
    home.packages = with pkgs; [ today yesterday tomorrow next-week ];
  };
}
