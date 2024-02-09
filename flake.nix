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
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Using a fork that is compatible with nixd
    flake-compat = {
      url = "github:inclyc/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    alacritty-theme = {
      url = "github:alexghr/alacritty-theme.nix";
      inputs.nixpkgs.follows = "nixpkgs";
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

  outputs =
    inputs@{ nixpkgs, flake-utils, home-manager, neovim, nix-darwin, ... }:
    let
      loadPkgs = system:
        import nixpkgs {
          inherit system;

          overlays = [
            inputs.alacritty-theme.overlays.default
            (import ./packages inputs)
          ];

          config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-25.9.0" "openssl-1.1.1w" ];
          };
        };
    in ({
      nixosConfigurations = {
        battlecruiser = nixpkgs.lib.nixosSystem {
          pkgs = loadPkgs "x86_64-linux";

          modules = [
            ./modules/nixos
            ./machines/battlecruiser
            home-manager.nixosModules.home-manager
          ];
        };
      };

      darwinConfigurations = {
        drone = nix-darwin.lib.darwinSystem {
          pkgs = loadPkgs "aarch64-darwin";
          modules =
            [ ./modules/darwin home-manager.darwinModules.home-manager ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.lib;
      let pkgs = loadPkgs system;
      in {
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;

        profiles = {
          battlecruiser = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                neovim.hmModule
                ./modules/home
                ./machines/battlecruiser/home.nix
              ];
            };
          };

          drone = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [ neovim.hmModule ./modules/home ./machines/drone.nix ];
            };
          };
        };

        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [ nixfmt nixd deadnix ];
        };
      }));
}
