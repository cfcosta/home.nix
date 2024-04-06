{ pkgs, lib, ... }:
with lib;
let
  inherit (pkgs.stdenv) isDarwin;
in
{
  home.file =
    if isDarwin then
      { "Library/Application Support/Element/config.json".text = builtins.readFile ./files/config.json; }
    else
      { ".config/Element/config.json".text = builtins.readFile ./files/config.json; };
}
