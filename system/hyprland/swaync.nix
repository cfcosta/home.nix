{ config, lib, ... }:
let
  inherit (lib) optionals;
  nvidiaEnabled = config.dusk.system.nixos.nvidia.enable;
in
{
  home-manager.users.${config.dusk.username} = {
    services.swaync.enable = true;

    # Fix for https://github.com/ErikReider/SwayNotificationCenter/issues/619
    # Makes swaync hang after a single notification has been sent, only on Nvidia.
    systemd.user.services.swaync.Service.Environment = optionals nvidiaEnabled [
      "GSK_RENDERER=gl"
      "GTK_DISABLE_VULKAN=1"
    ];
  };
}
