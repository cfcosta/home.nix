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

  networking.hostName = "battlecruiser";

  time.timeZone = "America/Sao_Paulo";

  dusk = {
    enable = true;
    user = "cfcosta";

    amd.enable = true;
    benchmarking.enable = true;
    containers.enable = true;
    gaming.enable = true;
    gnome.enable = true;
    icognito.enable = true;
    libvirt.enable = true;
    sound.enable = true;
    tailscale.enable = true;

    nvidia = {
      enable = true;
      powerLimit = 150;
    };
  };

  # Workaround fix for nm-online-service from stalling on Wireguard interface.
  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;
}
