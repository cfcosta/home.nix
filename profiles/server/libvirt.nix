{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    optionals
    ;
  inherit (pkgs.stdenv) isLinux;
in
{
  options.protoss.server.libvirt = {
    enable = mkOption {
      type = types.bool;
      default = isLinux;
      description = "Whether or not to enable Docker for running containers.";
    };
  };

  config = mkIf config.protoss.server.libvirt.enable {
    virtualisation.libvirtd = {
      enable = true;
      enableKVM = true;
    };

    environment.systemPackages = optionals config.protoss.gnome.enable (
      with pkgs;
      [
        virt-manager
        gnome.gnome-boxes
      ]
    );

    users.users."${config.protoss.user.username}".extraGroups = [ "libvirtd" ];
  };
}
