{ config, pkgs, ... }: {
  nix.settings.substituters =
    [ "https://cfcosta-home.cachix.org" "https://cache.nixos.org" ];

  nix.settings.trusted-public-keys = [
    "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  boot.loader.systemd-boot.enable = true;

  networking.hostName = "devos";

  time.timeZone = "America/Sao_Paulo";

  hardware.opengl.enable = true;

  virtualisation.memorySize = 8192;
  virtualisation.cores = 4;

  devos = {
    enable = true;

    user = "devos";

    containers.enable = true;
    gaming.enable = false;
    gnome.enable = true;
    icognito.enable = false;

    sound.enable = true;
    tailscale.enable = true;
  };
}
