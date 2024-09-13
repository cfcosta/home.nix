{
  config,
  lib,
  ...
}:
let
  inherit (builtins) readFile toJSON;
in
{
  config = {
    home = {
      activation.setupZedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cp -Lrf $HOME/.config/zed/settings.nix.json $HOME/.config/zed/settings.json
      '';

      file = {
        ".config/zed/settings.nix.json" = {
          force = true;
          text = toJSON (import ./settings.nix);
        };
        ".config/zed/keymap.json".text = readFile ./keymap.json;
      };
    };

  };
}
