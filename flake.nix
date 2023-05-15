{
  description = "Entrypoint for my user config";

  nixConfig.substituters = [
    "https://cache.nixos.org"
    "https://cfcosta-home.cachix.org"
    "https://cuda-maintainers.cachix.org"
  ];

  nixConfig.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
  ];

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nvchad = {
      url = "github:cfcosta/nvchad";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, flake-utils, rust-overlay, nvchad, ... }:
    let
      system = "x86_64-linux";
      customPackages = _: _: {
        devos = let rust = pkgs.rust-bin.stable.latest;
        in {
          rust-full = rust.default.override {
            extensions = [ "rust-src" "clippy" "rustfmt" "rust-analyzer" ];
          };

          inherit (rust) rust-analyzer;
          inherit (rust) rustfmt;
        };
      };

      overlays = [ rust-overlay.overlays.default customPackages ];
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      buildFormatScript = pkgs:
        pkgs.writeShellScriptBin "env-format" ''
          set -e

          for file in $(find . -name "*.nix"); do
            echo "Formatting $file..."
            nixfmt "$file"
          done
        '';
    in {
      nixosConfigurations.mothership = nixpkgs.lib.nixosSystem {
        inherit system pkgs;

        modules = [
          ./modules/nixos
          ./machines/mothership
          home-manager.nixosModules.home-manager
        ];
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      with nixpkgs.lib;
      let
        customPackages = _: _: {
          devos = let rust = pkgs.rust-bin.stable.latest;
          in {
            rust-full = rust.default.override {
              extensions = [ "rust-src" "clippy" "rustfmt" "rust-analyzer" ];
            };

            inherit (rust) rust-analyzer;
            inherit (rust) rustfmt;
          };
        };

        overlays = [ rust-overlay.overlays.default customPackages ];
        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };
      in {
        home-manager.useUserPackages = true;
        home-manager.useGlobalPkgs = true;

        profiles = {
          mothership = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                nvchad.hmModule
                ./modules/home-manager
                ./machines/mothership/home.nix
              ];
            };
          };

          darwin = {
            home = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;

              modules = [
                nvchad.hmModule
                ./modules/home-manager
                ./machines/darwin.nix
              ];
            };
          };
        };

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            nixfmt
            rnix-lsp
            (buildFormatScript pkgs)
          ];
        };
      });
}
