{ config, lib, ... }:
with lib;
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
      # load the defaults automatically
      default = [ ];
      description = "List of modules to enable";
    };

    config = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional configuration for Dusk OS";
    };
  };

  config = {
    assertions = [
      {
        assertion = all (
          module: pathExists (./. + "/${module}/${config.dusk-os.type}.nix")
        ) config.dusk-os.modules;
        message = "Module ${module} does not have a ${config.dusk-os.type}.nix file";
      }
    ];

    imports = map (module: ./. + "/${module}/${config.dusk-os.type}.nix") config.dusk-os.modules;
  };
}
