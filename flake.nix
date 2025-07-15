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
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";

    flake-compat.url = "github:nix-community/flake-compat";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    systems.url = "github:nix-systems/default";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    glimpse = {
      url = "github:seatedro/glimpse";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        flake-utils.follows = "flake-utils";
      };
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        gitignore.follows = "gitignore";
        pre-commit-hooks.follows = "pre-commit-hooks";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
        flake-compat.follows = "flake-compat";
      };
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-utils,
      nix-darwin,
      nixpkgs,
      pre-commit-hooks,
      rust-overlay,
      ...
    }:
    let
      ctx = flake-utils.lib.eachDefaultSystem (system: {
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            (import rust-overlay)
            (import ./packages inputs)
          ];

          config.allowUnfree = true;
        };
      });

      buildPkgs = system: ctx.pkgs.${system};
      builders = {
        nixos = nixpkgs.lib.nixosSystem;
        darwin = nix-darwin.lib.darwinSystem;
      };

      buildSystem =
        flavor: system: name:
        builders.${flavor} {
          pkgs = buildPkgs system;

          modules = [
            ./system
            ./system/${flavor}
            ./machines/${name}.nix
          ];

          specialArgs = { inherit inputs flavor; };
        };
      buildNixos = buildSystem "nixos" "x86_64-linux";
      buildDarwin = buildSystem "darwin" "aarch64-darwin";

      perSystem = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = buildPkgs system;

          inherit (pkgs) mkShell;

          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;

            hooks = {
              deadnix.enable = true;
              statix.enable = true;
              shellcheck.enable = true;

              treefmt = {
                enable = true;
                package = pkgs.dusk-treefmt;
              };
            };
          };
        in
        {
          checks = { inherit pre-commit-check; };
          formatter = pkgs.dusk-treefmt;

          devShells.default = mkShell {
            inherit (pre-commit-check) shellHook;
            name = "home";

            packages = with pkgs; [
              dusk-treefmt

              (writeShellScriptBin "dusk-apply" "nix run $(pwd)#dusk-apply")
            ];
          };

          packages = { inherit (pkgs) dusk-apply dusk-system-verify; };
        }
      );
    in
    perSystem
    // {
      darwinConfigurations.drone = buildDarwin "drone";
      nixosConfigurations.battlecruiser = buildNixos "battlecruiser";
    };
}
