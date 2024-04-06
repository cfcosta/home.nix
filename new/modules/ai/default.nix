{ config, lib, ... }:
with lib;
let
  cfg = config.dusk-os.modules.ai;
in
{
  options.dusk-os.modules.ai = {
    only = mkOption {
      type = types.listOf (types.enum [ "ollama" ]);
      default = [ "ollama" ];
      description = "List of AI apps to include";
    };
  };

  config = mkIf (cfg.only != [ ]) { imports = map (app: ./. + "/${app}") cfg.only; };
}
