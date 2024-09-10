{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
in
{
  imports = [
    ./dusk.nix
  ];

  config = {
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

      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      refind
      efibootmgr
    ];

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

    hardware = {
      enableRedistributableFirmware = true;
      cpu.amd.updateMicrocode = true;
    };

    networking = {
      hostName = "battlecruiser";

      useDHCP = mkDefault true;
    };

    time.timeZone = "America/Sao_Paulo";

    swapDevices = [ ];

    system.activationScripts = {
      refind-install = {
        deps = [ ];
        text = ''
          if [ -s /run/current-system/sw/bin/refind-install ];then
            if [ ! -s /boot/EFI/refind/refind_x64.efi ]; then
              OLDPATH="$PATH"
              PATH="/run/current-system/sw/bin"
          ${pkgs.refind}/bin/refind-install
              PATH="$OLDPATH"
              printf 'true' > /tmp/refind
            else
              printf 'installed/true' > /tmp/refind
            fi
          else
            printf 'skip/true' > /tmp/refind
          fi
        '';
      };
    };

    # Workaround fix for nm-online-service from stalling on Wireguard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
