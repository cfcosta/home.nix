{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.dusk.libvirt;
  inherit (lib) mkEnableOption mkIf;
in
{
  options.dusk.libvirt.enable = mkEnableOption "libvirt";

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      virt-manager
      gnome-boxes
    ];

    virtualisation.libvirtd.enable = true;

    users.users.${config.dusk.user}.extraGroups = [ "libvirtd" ];
  };
}
