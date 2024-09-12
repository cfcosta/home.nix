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
      agenix,
      alacritty-theme-nix,
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
            alacritty-theme-nix.overlays.default
            (_: _: {
              dusk.inputs = self.inputs;
            })
          ];

          config = {
            allowUnfree = true;
            enableCuda = system == "x86_64-linux";
          };
        };

      # nixos =
      #   system:
      #   nixpkgs.lib.nixosSystem {
      #     pkgs = buildPkgs system;
      #     modules = [ ./common/module.nix ];
      #
      #     specialArgs = {
      #       inherit (self) inputs;
      #     };
      #   };
      darwin =
        system:
        nix-darwin.lib.darwinSystem {
          pkgs = buildPkgs system;
          modules = [ ./common/module.nix ];

          specialArgs = {
            inherit (self) inputs;
          };
        };

      perSystem =
        system:
        let
          inherit (buildPkgs system) mkShell;

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
        in
        {
          inherit checks;

          devShells.default = mkShell {
            inherit (checks.pre-commit-check) shellHook;

            packages = [
              agenix.packages.${system}.default
            ];
          };
        };
    in
    flake-utils.lib.eachDefaultSystem perSystem
    // {
      # nixosConfigurations = {
      #   dusk = nixos "x86_64-linux";
      #   battlecruiser = nixos "x86_64-linux";
      # };

      darwinConfigurations = {
        dusk = darwin "aarch64-darwin";
        drone = darwin "aarch64-darwin";
      };
    };
}
