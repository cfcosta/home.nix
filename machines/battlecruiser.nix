_: {
  config = {
    dusk.system = {
      hostname = "battlecruiser";

      nixos = {
        desktop.alacritty.font.family = "Berkeley Mono NerdFont Mono";
        server.enable = false;
      };
    };

    boot = {
      initrd = {
        availableKernelModules = [
          "nvme"
          "ahci"
          "thunderbolt"
          "xhci_pci"
          "usbhid"
          "usb_storage"
          "sd_mod"
        ];

        kernelModules = [ "kvm-amd" ];
      };
    };

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/267a2e89-f17c-4ae8-ba84-709fda2a95aa";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/0B55-0450";
        fsType = "vfat";
      };
    };
    swapDevices = [ ];

    # Workaround fix for nm-online-service from stalling on Wireguard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
