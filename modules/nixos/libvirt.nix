{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.libvirt;
in {
  options.devos.libvirt.enable = mkEnableOption "libvirt";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ virt-manager gnome.gnome-boxes ];

    virtualisation.libvirtd.enable = true;

    users.users.${config.devos.user}.extraGroups = [ "libvirtd" ];
  };
}
