{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.dusk.libvirt;
in
{
  options.dusk.libvirt.enable = mkEnableOption "libvirt";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      gnome.gnome-boxes
    ];

    virtualisation.libvirtd.enable = true;

    users.users.${config.dusk.user}.extraGroups = [ "libvirtd" ];
  };
}
