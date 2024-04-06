{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.dusk-os;
in
{
  options.dusk-os = {
    enable = mkEnableOption "Enable Dusk OS configuration";
    type = mkOption {
      type = types.enum [
        "nixos"
        "darwin"
      ];
      description = "The type of system (NixOS or Darwin)";
    };
    modules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "List of Dusk OS modules to include";
    };
    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional configuration for Dusk OS";
    };
  };

  config = mkIf cfg.enable {
    _module.args.dusk-os = {
      inherit (cfg) type modules config;
      lib = import ./lib.nix { inherit pkgs lib; };
    };

    imports = map (module: module.${cfg.type} or { }) cfg.modules;
  };
}
