{ config, pkgs, ... }:
{
  imports = [ ./hardware.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "battlecruiser";

  time.timeZone = "America/Sao_Paulo";

  dusk = {
    enable = true;
    user = "cfcosta";

    amd.enable = true;
    containers.enable = true;
    gaming.enable = true;
    gnome.enable = true;
    libvirt.enable = true;
    sound.enable = true;
    tailscale.enable = true;

    nvidia = {
      enable = true;
      powerLimit = 300;
    };
  };

  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
