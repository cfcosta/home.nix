{
  description = "Entrypoint for my user config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ nixpkgs, home-manager, flake-utils, ... }:
    with nixpkgs.lib; {
      nixosConfigurations = {
        mothership = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            home-manager.nixosModules.home-manager
            ./modules/nixos
            ./machines/mothership.nix
          ];
        };
      };
    };
}
