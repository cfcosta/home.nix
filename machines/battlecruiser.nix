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
        desktop = {
          alacritty.font.family = "Berkeley Mono NerdFont Mono";

          hyprland = {
            enable = true;

            monitors = [
              # Vertical 1440p Monitor
              {
                name = "DP-1";
                resolution = {
                  width = 2560;
                  height = 1440;
                };
                refreshRate = 144;
                scale = 1.0;
                position.special = "auto-left";
                transform = 1; # 90 degrees
              }

              # 4K monitor with 10-bit color and VRR
              {
                name = "HDMI-A-1";
                resolution.special = "highres";
                position.special = "auto-right";
                scale = "auto";
                bitDepth = 10;
                vrr = 1;
              }
            ];
          };

          gnome.enable = true;
        };

        networking.defaultNetworkInterface = "eno1";

        server = {
          enable = true;
          chat.enable = false;
        };
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

      "/media" = {
        device = "/dev/disk/by-uuid/12cdcfc5-77b8-4182-994d-a081c22669dd";
        fsType = "ext4";
      };
    };

    # Enable wacom tablets support
    hardware.opentabletdriver.enable = true;

    networking.firewall.allowedTCPPorts = [
      3000
      8096 # Jellyfin
    ];

    programs.steam.gamescopeSession.args = [
      "-r"
      "120"
      "--sdr-gamut-wideness"
      "1"
      "--hdr-enabled"
      "--adaptive-sync"
    ];

    swapDevices = [ ];

    # Workaround fix for nm-online-service from stalling on Wireguard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
