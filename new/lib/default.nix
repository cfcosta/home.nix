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
      type = types.listOf types.str;
      default = [ ];
      description = "List of modules to enable";
    };
    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional configuration for Dusk OS";
    };
    lib = mkOption {
      type = types.attrs;
      default = import ./lib.nix { inherit pkgs lib; };
      description = "Dusk OS library functions";
    };
  };

  config = mkIf cfg.enable {
    _module.args.dusk-os = {
      inherit (cfg)
        type
        modules
        config
        lib
        ;
    };

    imports = map (module: ../modules + "/${module}") cfg.modules;
  };
}
