{
  description = "Entrypoint for my user config";

  nixConfig.substituters =
    [ "https://cfcosta-home.cachix.org" "https://cache.nixos.org" ];

  nixConfig.trusted-public-keys = [
    "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
  ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    emacs-overlay.url = "github:nix-community/emacs-overlay";

    nix-doom-emacs.url = "github:nix-community/nix-doom-emacs";
    nix-doom-emacs.inputs.nixpkgs.follows = "nixpkgs";
    nix-doom-emacs.inputs.emacs-overlay.follows = "emacs-overlay";
  };

  outputs = inputs@{ nixpkgs, home-manager, flake-utils, emacs-overlay
    , nix-doom-emacs, ... }:
    with nixpkgs.lib;
    let
      system = "x86_64-linux";
      overlays = [ inputs.emacs-overlay.overlay ];
    in {
      home-manager.useUserPackages = true;
      home-manager.useGlobalPkgs = true;

      homeConfigurations = {
        "cfcosta@mothership" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};

          modules = [
            { nixpkgs.overlays = overlays; }
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
        in pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nixfmt
            rnix-lsp
            nodePackages.yaml-language-server
          ];
        };
      };
    };
}
