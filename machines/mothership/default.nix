{ config, pkgs, ... }: {
  imports = [ ./hardware.nix ];

  nix.settings.substituters =
    [ "https://cfcosta-home.cachix.org" "https://cache.nixos.org" ];

  nix.settings.trusted-public-keys = [
    "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = { "/crypto_keyfile.bin" = null; };

  networking.hostName = "mothership";

  time.timeZone = "America/Sao_Paulo";

  devos = {
    enable = true;

    user = "cfcosta";

    nvidia.enable = true;

    gaming.enable = false;
    gnome.enable = true;
    icognito.enable = true;

    containers.enable = true;
    libvirt.enable = true;
    virtualbox.enable = true;

    sound.enable = true;
    tailscale.enable = true;
  };
}
