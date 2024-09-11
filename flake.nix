{
  description = "Entrypoint for my user config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    agenix.url = "github:ryantm/agenix";

    alacritty-theme = {
      url = "github:alacritty/alacritty-theme";
      flake = false;
    };

    alacritty-theme-nix = {
      url = "github:alexghr/alacritty-theme.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        alacritty-theme.follows = "alacritty-theme";
      };
    };

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
  };

  outputs =
    {
      self,

      flake-utils,
      nix-darwin,
      nixpkgs,
      pre-commit-hooks,
      alacritty-theme-nix,
      ...
    }:
    let
      inherit (nixpkgs.lib) nixosSystem;
      inherit (nix-darwin.lib) darwinSystem;

      buildPkgs =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            alacritty-theme-nix.overlays.default
          ];

          config = {
            allowUnfree = true;
            enableCuda = system == "x86_64-linux";
          };
        };
    in
    {
      nixosConfigurations = {
        battlecruiser = nixosSystem {
          pkgs = buildPkgs "x86_64-linux";

          modules = [
            (import ./module.nix {
              inherit (self) inputs;
              hostname = "battlecruiser";
              flavor = "nixos";
            })
          ];
        };
      };

      darwinConfigurations = {
        drone = darwinSystem {
          pkgs = buildPkgs "aarch64-darwin";

          modules = [
            (import ./module.nix {
              inherit (self) inputs;
              hostname = "drone";
              flavor = "darwin";
            })
          ];
        };
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = buildPkgs system;
      in
      {
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

        devShells.default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;

          packages = [
            self.inputs.agenix.packages.${system}.default
          ];
        };
      }
    );
}
