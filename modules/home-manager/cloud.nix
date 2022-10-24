{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.devos.home;
  inherit (lib.hm.gvariant) mkTuple;
in {
  options = {
    devos.home.cloud = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.cloud.enable {
    home.packages = with pkgs; [ google-cloud-sdk kubectl ];
  };
}
