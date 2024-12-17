{ inputs, ... }:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-gpu-amd
    common-pc-ssd
  ];

  config = {
    dusk.system = {
      hostname = "terminus";

      monitors = [
        {
          name = "DP-1";

          bitDepth = 8;
          position = {
            x = 0;
            y = 0;
          };
          refreshRate = 74.99;
          resolution = {
            width = 2560;
            height = 1080;
          };
          scale = 1.0;
          transform = {
            rotate = 0;
            flipped = false;
          };
          vrr = false;
        }
      ];

      nixos = {
        nvidia.enable = false;

        desktop = {
          gaming.gamescope.enable = true;
          gnome.enable = true;
          hyprland.enable = true;
        };

        server.enable = false;
      };
    };

    boot.kernelModules = [ "kvm-amd" ];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/3db177d8-c700-4177-96e9-36145afc4d8c";
      fsType = "ext4";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/5877-C82A";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    swapDevices = [ { device = "/dev/disk/by-uuid/43837f7a-8272-4178-955e-d93b887c976e"; } ];

    # Workaround fix for nm-online-service from stalling on Wireguard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
