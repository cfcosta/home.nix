{ lib, pkgs, config, ... }: {
  imports = [
    ./containers.nix
    ./core.nix
    ./gaming.nix
    ./gnome.nix
    ./icognito.nix
    ./nvidia.nix
    ./sound.nix
    ./tailscale.nix
    ./virtualisation.nix
  ];
}
