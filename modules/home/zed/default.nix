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
    home.file.".config/zed/settings.json".text = toJSON (import ./settings.nix { inherit config; });
    home.file.".config/zed/keymap.json".text = readFile ./keymap.json;
  };
}
