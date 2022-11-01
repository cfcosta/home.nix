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
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-doom-emacs = {
      url = "github:nix-community/nix-doom-emacs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        emacs-overlay.follows = "emacs-overlay";
      };
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { nixpkgs, home-manager, flake-utils, emacs-overlay, nix-doom-emacs
    , rust-overlay, ... }:
    with nixpkgs.lib;
    let
      system = "x86_64-linux";
      overlays = [ emacs-overlay.overlay rust-overlay.overlays.default ];
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

      testVM = nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
          ./modules/nixos
          ./machines/vm
          home-manager.nixosModules.home-manager
          {
            home-manager.users.devos = {
              imports = [
                { nixpkgs.overlays = overlays; }

                nix-doom-emacs.hmModule
                ./modules/home-manager
                ./machines/vm/home.nix
              ];
            };
          }
        ];
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
