{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.virtualbox;
in {
  config = mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    users.users.${config.dusk.user.username}.extraGroups = [ "vboxusers" ];
  };
}
