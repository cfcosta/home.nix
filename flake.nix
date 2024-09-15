{
  description = "Entrypoint for my user config";

  nixConfig = {
    extra-substituters = [ "https://cfcosta-home.cachix.org/" ];
    extra-trusted-public-keys = [
      "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    catppuccin.url = "github:catppuccin/nix";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        flake-utils.follows = "flake-utils";
        gitignore.follows = "gitignore";
        pre-commit-hooks.follows = "pre-commit-hooks";
      };
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
        flake-compat.follows = "flake-compat";
      };
    };

    # Non-flakes
    catppuccin-cosmic = {
      url = "github:catppuccin/cosmic-desktop";
      flake = false;
    };
    catppuccin-refind = {
      url = "github:catppuccin/refind";
      flake = false;
    };
    waydroid-script = {
      url = "github:casualsnek/waydroid_script";
      flake = false;
    };
  };

  outputs =
    inputs@{
      flake-utils,
      nix-darwin,
      nixpkgs,
      pre-commit-hooks,
      ...
    }:
    let
      ctx = flake-utils.lib.eachDefaultSystem (system: {
        pkgs = import nixpkgs {
          inherit system;

          overlays = [ (import ./packages inputs) ];

          config.allowUnfree = true;
        };
      });

      buildPkgs = system: ctx.pkgs.${system};

      perSystem = flake-utils.lib.eachDefaultSystem (system: rec {
        checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;

          hooks = {
            deadnix.enable = true;
            nixfmt-rfc-style.enable = true;
            statix.enable = true;

            shellcheck.enable = true;
            shfmt.enable = true;
          };
        };

        devShells.default =
          with (buildPkgs system);
          mkShell {
            inherit (checks.pre-commit-check) shellHook;
            packages = [ agenix ];
          };
      });
    in
    perSystem
    // {
      nixosConfigurations = {
        battlecruiser = nixpkgs.lib.nixosSystem {
          pkgs = buildPkgs "x86_64-linux";

          modules = [
            ./system
            ./system/nixos
            ./machines/battlecruiser.nix
          ];

          specialArgs = {
            inherit inputs;

            flavor = "nixos";
          };
        };

        pylon = nixpkgs.lib.nixosSystem {
          pkgs = buildPkgs "x86_64-linux";

          modules = [
            ./system
            ./system/nixos
            ./machines/pylon.nix
          ];

          specialArgs = {
            inherit inputs;

            flavor = "nixos";
          };
        };
      };

      darwinConfigurations.drone = nix-darwin.lib.darwinSystem {
        pkgs = buildPkgs "aarch64-darwin";

        modules = [
          ./system
          ./system/darwin
          ./machines/drone.nix
        ];

        specialArgs = {
          inherit inputs;

          flavor = "darwin";
        };
      };
    };
}
