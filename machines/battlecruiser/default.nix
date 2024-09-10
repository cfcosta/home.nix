{ ... }:
{
  imports = [
    ./hardware.nix
    ./refind.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "battlecruiser";

  time.timeZone = "America/Sao_Paulo";

  dusk = {
    enable = true;
    user = "cfcosta";

    containers.enable = true;
    cosmic.enable = true;
    libvirt.enable = true;
    nvidia.enable = true;
    privacy.enable = true;
    tailscale.enable = true;
  };

  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
