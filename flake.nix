{
  description = "Entrypoint for my user config";

  nixConfig.substituters =
    [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];

  nixConfig.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
  ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    aiken = {
      url = "github:aiken-lang/aiken";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
    };

    whiz-cli = {
      url = "github:searchableguy/whiz";
      flake = false;
    };

    todoist-cli = {
      url =
        "github:psethwick/todoist?rev=2f80bdc65de44581c4497107a092c73f39ae0b62";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, flake-utils, neovim, aiken, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      devScripts = pkgs: [
        (pkgs.writeShellScriptBin "env-update-input"
          "nix flake lock --update-input $@")

        (pkgs.writeShellScriptBin "env-format" ''
          set -e

          for file in $(find . -name "*.nix"); do
            echo "Formatting $file..."
            nixfmt "$file"
          done
        '')
      ];
    in {
      nixosConfigurations = {
        battlecruiser = nixpkgs.lib.nixosSystem {
          inherit system pkgs;

          modules = [
            ./nixos
            ./machines/battlecruiser
            home-manager.nixosModules.home-manager
          ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.lib;
      let
        overlays = [
          (final: prev: { aiken = aiken.packages.${system}.default; })
          (import ./packages inputs)
        ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      in {
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;

        profiles = {
          battlecruiser = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                neovim.hmModule
                ./home-manager
                ./machines/battlecruiser/home.nix
              ];
            };
          };

          drone = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [ neovim.hmModule ./home-manager ./machines/drone.nix ];
            };
          };
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ nixfmt rnix-lsp (devScripts pkgs) ];
        };
      });
}
