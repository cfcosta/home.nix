{ inputs, ... }:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
  ];

  config = {
    dusk.system = {
      hostname = "terminus";

      monitors = [ ];

      nixos = {
        desktop = {
          alacritty.font.family = "Berkeley Mono NerdFont Mono";
          gaming.gamescope.enable = true;
          hyprland.enable = true;
        };

        server = {
          enable = true;
          domain = "cfcosta.cloud";
          sonarr.enable = false;
        };
      };

      zed = {
        buffer_font_family = "Berkeley Mono NerdFont Mono";
        buffer_font_size = "Berkeley Mono NerdFont Mono";
        ui_font_family = "Berkeley Mono NerdFont Mono";
        ui_font_size = "Berkeley Mono NerdFont Mono";
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

    programs.steam.gamescopeSession.args = [
      "--steam"
      "--adaptive-sync"

      "-r"
      "120"

      "--prefer-output"
      "HDMI-2"

      "--output-width"
      "1920"

      "--output-height"
      "1080"
    ];

    swapDevices = [ ];

    # Workaround fix for nm-online-service from stalling on Wireguard interface.
    # https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
