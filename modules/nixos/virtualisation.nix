{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.virtualisation;
in {
  options = {
    devos.virtualisation.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable virt-manager and qemu-kvm
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ virt-manager gnome.gnome-boxes ];

    virtualisation.libvirtd.enable = true;

    users.users.${config.devos.user}.extraGroups = [ "libvirtd" ];
  };
}
