{
  description = "Entrypoint for my user config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
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
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    duskpi = {
      url = "github:cfcosta/duskpi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        llm-agents.follows = "llm-agents";
        skill-hunk.follows = "hunk";
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
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    hunk = {
      url = "github:modem-dev/hunk";
      flake = false;
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim = {
      url = "github:cfcosta/neovim.nix";
      inputs = {
        gitignore.follows = "gitignore";
        nixpkgs.follows = "nixpkgs";
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
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nm-wifi = {
      url = "github:cfcosta/nm-wifi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        rust-overlay.follows = "rust-overlay";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    proton-cachyos = {
      url = "github:powerofthe69/proton-cachyos-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
                inputs.proton-cachyos.overlays.default

                # Override fetchurl's User-Agent. crates.io's CloudFront 403s
                # anything starting with `curl/`, which is exactly what
                # nixpkgs' fetchurl hard-codes (`curl/<ver> Nixpkgs/<ver>`),
                # so every crate fetch fails on a cache miss (e.g. bun2nix's
                # vendored deps when building Hunk). `curlOptsList` is
                # appended after the default `--user-agent`, and curl honors
                # the last `-A`, so this overrides per call. We swap only the
                # `__functor` so `pkgs.fetchurl.override`/`.overrideAttrs`
                # and friends keep working, and we handle the fixed-point
                # call style (`fetchurl (finalAttrs: { ... })`) as well as
                # plain attrset args.
                (_: super: {
                  fetchurl = super.fetchurl // {
                    __functor =
                      _: args:
                      let
                        extend = previous: {
                          curlOptsList = (previous.curlOptsList or [ ]) ++ [
                            "--user-agent"
                            "Nixpkgs-fetchurl"
                          ];
                        };
                      in
                      super.fetchurl (
                        if builtins.isFunction args then final: args final // extend (args final) else args // extend args
                      );
                  };
                })
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
      devShells = forEachSupportedSystem (
        { pkgs, system }:
        {
          default = pkgs.mkShell {
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
