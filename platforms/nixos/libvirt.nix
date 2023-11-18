{ lib, pkgs, config, ... }:
with lib; {
  config = {
    environment.systemPackages = with pkgs; [ virt-manager gnome.gnome-boxes ];

    virtualisation.libvirtd.enable = true;

    users.users.${config.dusk.user}.extraGroups = [ "libvirtd" ];
  };
}
