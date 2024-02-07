{ pkgs, lib, config, ... }:
with lib; {
  nix = {
    useDaemon = true;

    gc.automatic = true;

    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];

      trusted-substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
      substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];

      system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    };
  };
}
