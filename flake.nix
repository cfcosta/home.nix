{
  description = "Entrypoint for my user config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";
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
      };
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
      };
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
      buildPkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            inputs.agenix.overlays.default
            (import ./system/overlay inputs)
          ];
          config.allowUnfree = true;
        };

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
      nixosConfigurations.battlecruiser = nixpkgs.lib.nixosSystem {
        pkgs = buildPkgs "x86_64-linux";

        modules = [
          ./options.nix
          ./user.nix
          ./system
          ./machines/battlecruiser.nix
        ];

        specialArgs = {
          inherit inputs;
          flavor = "nixos";
        };
      };

      darwinConfigurations.drone = nix-darwin.lib.darwinSystem {
        pkgs = buildPkgs "aarch64-darwin";

        modules = [
          ./options.nix
          ./user.nix
          ./system
          ./machines/drone.nix
        ];

        specialArgs = {
          inherit inputs;
          flavor = "darwin";
        };
      };
    };
}
