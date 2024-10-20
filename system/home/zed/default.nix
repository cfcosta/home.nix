{ pkgs, lib, ... }:
let
  inherit (builtins) toJSON;

  settingsFile = pkgs.writeText "zed-settings.json" (
    toJSON (
      import ./settings.nix {
        inherit pkgs;
      }
    )
  );
in
{
  config.home.activation.setupZedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.jq}/bin/jq '.' ${settingsFile} > $HOME/.config/zed/settings.json
    ${pkgs.jq}/bin/jq '.' ${./keymap.json} > $HOME/.config/zed/keymap.json
  '';
}
