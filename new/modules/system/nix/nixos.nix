{ pkgs, ... }:
{
  environment.etc."nix/inputs/nixpkgs".source = "${pkgs.dusk.inputs.nixpkgs}";
  environment.etc."nix/inputs/nix-darwin".source = "${pkgs.dusk.inputs.nix-darwin}";

  nix = {
    gc.automatic = true;

    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      system-features = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };

    # Configure nix to use the flake's nixpkgs
    registry.nixpkgs.flake = pkgs.dusk.inputs.nixpkgs;
    registry.nix-darwin.flake = pkgs.dusk.inputs.nix-darwin;
    nixPath = lib.mkForce [ "/etc/nix/inputs" ];
  };
}
