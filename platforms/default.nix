{ inputs, mkSystem }: {
  battlecruiser = mkSystem "battlecruiser" {
    kind = "nixos";
    system = "x86_64-linux";
    users = [{
      name = "cfcosta";
      initialPassword = "dusk";
    }];

    modules = {
      enable = [
        "amd-cpu"
        "benchmarking"
        "containers"
        "default"
        "gaming"
        "gnome"
        "icognito"
        "libvirt"
        "nvidia"
        "sound"
        "tailscale"
      ];

      config.nvidia.powerLimit = 150;
    };

    extraConfig = { config, lib, pkgs, modulesPath, ... }: {
      imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

      nix.settings.substituters =
        [ "https://cfcosta-home.cachix.org" "https://cache.nixos.org" ];
      nix.settings.trusted-public-keys = [
        "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      boot.extraModulePackages = [ ];
      boot.initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "sd_mod"
        "thunderbolt"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];
      boot.initrd.kernelModules = [ ];

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

      networking.hostName = "battlecruiser";
      networking.useDHCP = lib.mkDefault true;

      swapDevices = [ ];

      # Workaround fix for nm-online-service from stalling on Wireguard interface.
      # https://github.com/NixOS/nixpkgs/issues/180175
      systemd.services.NetworkManager-wait-online.enable = false;

      time.timeZone = "America/Sao_Paulo";
    };
  };

  drone = mkSystem {
    kind = "darwin";
    system = "aarch64-darwin";
    users = [{
      name = "cfcosta";
      initialPassword = "dusk";
    }];
  };
}
