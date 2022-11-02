{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.virtualbox;
in {
  options.devos.virtualbox.enable = mkEnableOption "virtualbox";

  config = mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    users.users.${config.devos.user}.extraGroups = [ "vboxusers" ];
  };
}
