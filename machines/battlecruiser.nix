{ inputs, ... }:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
  ];

  config = {
    dusk.system = {
      hostname = "battlecruiser";

      nixos = {
        desktop.alacritty.font.family = "Berkeley Mono NerdFont Mono";

        networking = {
          defaultNetworkInterface = "eno1";
          ip = "10.0.0.2";
          nameservers = [
            "10.0.0.4"
            "1.1.1.1" # Cloudflare
            "1.0.0.1" # Cloudflare
            "8.8.8.8" # Google
            "4.4.4.4" # Google
          ];
        };

        server.enable = true;
      };
    };

    boot.initrd.kernelModules = [ "kvm-amd" ];

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
