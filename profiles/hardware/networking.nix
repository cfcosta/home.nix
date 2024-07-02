{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.stdenv) isLinux;
  cfg = config.protoss.hardware.networking;
in
{
  options.protoss.hardware.networking = {
    enable = mkOption {
      type = types.bool;
      default = isLinux;
      description = "Enable NetworkManager";
    };
  };

  config = lib.mkIf cfg.enable { networking.networkmanager.enable = true; };
}
