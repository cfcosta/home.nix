{ config, ... }:
let
  cfg = config.dusk-os.modules.messaging;
in
{
  options.dusk-os.modules.messaging = {
    only = mkOption {
      type = types.listOf (types.enum [ "element" ]);
      default = [ ];
      description = "List of messaging apps to include";
    };
  };

  config = {
    imports = map (app: ./. + "/${app}") cfg.only;
  };
}
