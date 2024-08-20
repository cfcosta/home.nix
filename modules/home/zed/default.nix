{ config, lib, ... }:
let
  inherit (builtins) readFile toJSON;
  inherit (lib) mkEnableOption mkIf;

  cfg = config.dusk.home;
in
{
  options = {
    dusk.home.zed = {
      enable = mkEnableOption "Zed editor";
    };
  };

  config = mkIf cfg.zed.enable {
    home.file.".config/zed/settings.nix.json" = {
      force = true;
      text = toJSON (import ./settings.nix { inherit config; });
    };

    home.activation.setupZedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      [ -f $HOME/.config/zed/settings.json ] && rm $HOME/.config/zed/settings.json
      cp -Lrf $HOME/.config/zed/settings.nix.json $HOME/.config/zed/settings.json
    '';

    home.file.".config/zed/keymap.json".text = readFile ./keymap.json;
  };
}
