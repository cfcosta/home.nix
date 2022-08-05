{
  description = "Entrypoint for my user config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, flake-utils, nix-doom-emacs, ... }:
    with nixpkgs.lib;
    let system = "x86_64-linux";
    in {
      homeConfigurations = {
        "cfcosta@mothership" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [
            nix-doom-emacs.hmModule
            ./modules/home-manager
            ./machines/mothership/home.nix
          ];
        };
      };

      nixosConfigurations = {
        mothership = nixpkgs.lib.nixosSystem {
          inherit system;

          modules = [
            ./modules/nixos
            ./machines/mothership
            home-manager.nixosModules.home-manager
          ];
        };
      };

      devShell = {
        "${system}" = let pkgs = nixpkgs.legacyPackages.${system}.pkgs;
        in pkgs.mkShell { nativeBuildInputs = with pkgs; [ nixfmt ]; };
      };
    };
}
