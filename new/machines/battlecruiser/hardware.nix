{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.extraModulePackages = [ ];
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "thunderbolt"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/267a2e89-f17c-4ae8-ba84-709fda2a95aa";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0B55-0450";
    fsType = "vfat";
  };

  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  networking.hostName = "battlecruiser";
  networking.useDHCP = lib.mkDefault true;

  swapDevices = [ ];

  time.timeZone = "America/Sao_Paulo";
}
