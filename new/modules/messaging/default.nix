{ config, lib, ... }:
with lib;
let
  cfg = config.dusk-os.modules.messaging;
in
{
  options.dusk-os.modules.messaging = {
    only = mkOption {
      type = types.listOf (types.enum [ "element" ]);
      default = [ "element" ];
      description = "List of messaging apps to include";
    };
  };

  config = mkIf (cfg.only != [ ]) { imports = map (app: ./. + "/${app}") cfg.only; };
}
