{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.home;
  directory = builtins.replaceStrings [ "~" ] [ "$HOME" ] cfg.folders.notes;
  buildTool =
    name: cmd:
    pkgs.writeShellApplication {
      inherit name;
      text = ''
        ROOT="${directory}/journal/$(${cmd} +%Y)/$(${cmd} +%m)"
        [ -d "$ROOT" ] || mkdir -p "$ROOT"
        $EDITOR "$ROOT/$(${cmd} +%d).md"  
      '';
    };
  today = buildTool "today" "date";
  yesterday = buildTool "yesterday" ''date -d "yesterday"'';
  tomorrow = buildTool "tomorrow" ''date -d "tomorrow"'';
  next-week = buildTool "next-week" ''date -d "next monday"'';
in
{
  options.dusk.home = {
    notes.enable = mkEnableOption "notes";

    folders.notes = mkOption {
      type = types.str;
      default = "~/Notes";
    };
  };

  config = mkIf cfg.notes.enable {
    home.packages = with pkgs; [
      today
      yesterday
      tomorrow
      next-week
    ];
  };
}
