{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.virtualbox;
in
{
  options.dusk.virtualbox.enable = mkEnableOption "virtualbox";

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    users.users.${config.dusk.user}.extraGroups = [ "vboxusers" ];
  };
}
