{ lib, pkgs, config, ... }:
with lib; {
  config = {
    virtualisation.virtualbox.host.enable = true;
    users.users.${config.dusk.user}.extraGroups = [ "vboxusers" ];
  };
}
