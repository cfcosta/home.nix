{
  description = "Entrypoint for my user config";

  nixConfig = {
    extra-substituters = [ "https://cfcosta-home.cachix.org/" ];
    extra-trusted-public-keys = [
      "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    beads = {
      url = "github:steveyegge/beads/v0.49.1";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    docbert = {
      url = "github:cfcosta/docbert";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    duskpi = {
      url = "github:cfcosta/duskpi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        llm-agents.follows = "llm-agents";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hypr-recorder = {
      url = "github:cfcosta/hypr-recorder";
      inputs = {
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs = {
        flake-utils.follows = "flake-utils";
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
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
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nm-wifi = {
      url = "github:cfcosta/nm-wifi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pre-commit-hooks.follows = "pre-commit-hooks";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
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
    {
      self,
      nix-darwin,
      nixos-generators,
      nixpkgs,
      pre-commit-hooks,
      rust-overlay,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;

      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forEachSupportedSystem =
        f:
        lib.genAttrs supportedSystems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;

              overlays = [
                (import rust-overlay)
                (import ./packages inputs)
              ];

              config.allowUnfree = true;
            };
          }
        );

      pkgsFor = forEachSupportedSystem ({ pkgs, ... }: pkgs);

      builders = {
        darwin = nix-darwin.lib.darwinSystem;
        nixos = nixpkgs.lib.nixosSystem;
      };

      buildSystem =
        flavor: system: name:
        builders.${flavor} {
          pkgs = pkgsFor.${system};

          modules = [
            ./system
            ./system/${flavor}
            ./machines/${name}.nix
          ];

          specialArgs = { inherit inputs flavor; };
        };
    in
    {
      checks = forEachSupportedSystem (
        { pkgs, system }:
        let
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
          inherit pre-commit-check;
        }
      );

      devShells = forEachSupportedSystem (
        { pkgs, system }:
        let
          inherit (self.checks.${system}) pre-commit-check;
        in
        {
          default = pkgs.mkShell {
            inherit (pre-commit-check) shellHook;
            name = "home";

            packages = with pkgs; [
              self.formatter.${system}

              (writeShellScriptBin "dusk-apply" "nix run $(pwd)#dusk-apply")
            ];
          };
        }
      );

      formatter = forEachSupportedSystem ({ pkgs, ... }: pkgs.dusk-treefmt);

      packages = forEachSupportedSystem (
        { pkgs, system }:
        {
          inherit (pkgs) dusk-apply dusk-system-verify;
        }
        // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          iso = nixos-generators.nixosGenerate {
            inherit system pkgs;

            modules = [
              ./system
              ./system/nixos
              ./machines/live.nix
            ];

            specialArgs = {
              inherit inputs;
              flavor = "nixos";
            };

            format = "iso";
          };
        }
      );

      darwinConfigurations.drone = buildSystem "darwin" "aarch64-darwin" "drone";
      nixosConfigurations.battlecruiser = buildSystem "nixos" "x86_64-linux" "battlecruiser";
    };
}
