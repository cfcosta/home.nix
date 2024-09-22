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
    aider-chat = {
      url = "github:paul-gauthier/aider";
      flake = false;
    };
    catppuccin-cosmic = {
      url = "github:catppuccin/cosmic-desktop";
      flake = false;
    };
    catppuccin-gitui = {
      url = "github:catppuccin/gitui";
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
      self,

      flake-utils,
      nix-darwin,
      nixpkgs,
      pre-commit-hooks,
      neovim,
      ...
    }:
    let
      ctx = flake-utils.lib.eachDefaultSystem (system: {
        pkgs = import nixpkgs {
          inherit system;

          overlays = [
            neovim.overlays.default
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

          specialArgs = {
            inherit inputs flavor;
          };
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
              nixfmt-rfc-style.enable = true;
              statix.enable = true;

              shellcheck.enable = true;
              shfmt.enable = true;
            };
          };

          systemTarget =
            name: flavor:
            let
              prefix = {
                nixos = "nixosConfigurations";
                darwin = "darwinConfigurations";
              };
            in
            self.outputs.${prefix.${flavor}}.${name}.config.system.build.toplevel;
        in
        {
          checks = {
            inherit pre-commit-check;
          };

          devShells.default = mkShell {
            inherit (pre-commit-check) shellHook;
            packages = with pkgs; [ agenix ];
          };

          packages = pkgs.dusk // {
            battlecruiser = systemTarget "battlecruiser" "nixos";
            drone = systemTarget "drone" "darwin";
          };
        }
      );
    in
    perSystem
    // {
      darwinConfigurations.drone = buildDarwin "drone";
      nixosConfigurations.battlecruiser = buildNixos "battlecruiser";
    };
}
