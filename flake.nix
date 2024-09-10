{
  description = "Entrypoint for my user config";

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

    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        gitignore.follows = "gitignore";
      };
    };

    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      neovim,
      nix-darwin,
      pre-commit-hooks,
      nixos-cosmic,
      ...
    }:
    let
      loadPkgs =
        system:
        import nixpkgs {
          inherit system;

          overlays = [
            inputs.alacritty-theme-nix.overlays.default
            (import ./packages inputs)
          ];

          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "electron-25.9.0"
              "openssl-1.1.1w"
            ];
          };
        };
    in
    (
      {
        nixosConfigurations = {
          battlecruiser = nixpkgs.lib.nixosSystem {
            pkgs = loadPkgs "x86_64-linux";

            modules = [
              {
                nix.settings = {
                  substituters = [ "https://cosmic.cachix.org/" ];
                  trusted-public-keys = [
                    "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
                  ];
                };
              }
              nixos-cosmic.nixosModules.default
              ./modules/nixos
              ./machines/battlecruiser
              home-manager.nixosModules.home-manager
            ];
          };
        };

        darwinConfigurations = {
          drone = nix-darwin.lib.darwinSystem {
            pkgs = loadPkgs "aarch64-darwin";
            modules = [
              ./modules/darwin
              home-manager.darwinModules.home-manager
            ];
          };
        };
      }
      // flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = loadPkgs system;
        in
        {
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
                modules = [
                  neovim.hmModule
                  ./modules/home
                  ./machines/drone/home.nix
                ];
              };
            };
          };

          checks.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;

            hooks = {
              nixfmt-rfc-style.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;

            nativeBuildInputs = with pkgs; [
              nixfmt-rfc-style
              deadnix
            ];
          };
        }
      )
    );
}
