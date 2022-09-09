{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.initrd.secrets = { "/crypto_keyfile.bin" = null; };

  networking.hostName = "mothership";

  time.timeZone = "America/Sao_Paulo";

  services.xserver.videoDrivers = [ "nvidia" ];

  devos = {
    enable = true;

    user = "cfcosta";

    containers.enable = true;
    gaming.enable = false;
    gnome.enable = true;
    icognito.enable = false;
    sound.enable = true;
    tailscale.enable = true;
    virtualisation.enable = true;
  };
}
