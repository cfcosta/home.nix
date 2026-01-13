{ config, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      pcmanfm
      tumbler
    ];

    services.tumbler.enable = true;

    home-manager.users.${config.dusk.username} = _: {
      # Open directories with PCManFM
      xdg.mimeApps.defaultApplications."inode/directory" = "pcmanfm.desktop";
    };
  };
}
