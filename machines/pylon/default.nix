{ ... }:
{
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "pylon";

  time.timeZone = "America/Sao_Paulo";

  dusk = {
    enable = true;
    user = "cfcosta";

    containers.enable = true;
    gaming.enable = true;
    gnome.enable = true;
    libvirt.enable = true;
    sound.enable = true;
    tailscale.enable = true;
  };

  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
