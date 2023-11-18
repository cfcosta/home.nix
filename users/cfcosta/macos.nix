{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.dusk.home;
  inherit (lib.hm.gvariant) mkTuple;
in {
  options.dusk.home.macos.enable = mkOption {
    default = pkgs.stdenv.isDarwin;
    example = true;
    description = "Whether to enable MacOS extensions.";
    type = lib.types.bool;
  };

  config = mkIf cfg.macos.enable {
    home.file."Library/Application Support/Element/config.json".text =
      builtins.readFile ./element/config.json;
  };
}
