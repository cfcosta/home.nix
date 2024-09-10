{ config, lib, ... }:
let
  inherit (builtins) readFile toJSON;
in
lib.optionalAttrs config.dusk.zed.enable {
  home = {
    activation.setupZedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cp -Lrf $HOME/.config/zed/settings.nix.json $HOME/.config/zed/settings.json
    '';

    file = {
      ".config/zed/settings.nix.json" = {
        force = true;
        text = toJSON (import ./settings.nix { inherit config; });
      };
      ".config/zed/keymap.json".text = readFile ./keymap.json;
    };
  };

}
