{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    let
      loadPkgs =
        system:
        import nixpkgs {
          inherit system;

          overlays = [ (import ./overlays) ];

          config.allowUnfree = true;
        };
    in
    (
      {
        darwinConfigurations = {
          # Add your Darwin configurations here
        };

        nixosConfigurations = {
          battlecruiser = nixpkgs.lib.nixosSystem {
            pkgs = loadPkgs "x86_64-linux";

            modules = [
              ./modules
              ./machines/battlecruiser
              (
                { ... }:
                {
                  system.stateVersion = "24.05";
                }
              )
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
          devShells.default =
            with pkgs;
            mkShell {
              nativeBuildInputs = [
                deadnix
                nixfmt-rfc-style
              ];
            };
        }
      )
    );
}
