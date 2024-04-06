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
    {
      nixpkgs,
      flake-utils,
      nix-darwin,
      ...
    }:
    let
      loadPkgs =
        system:
        import nixpkgs {
          inherit system;

          overlays = [ (import ./overlays) ];

          config.allowUnfree = true;
        };

      machines = import ./machines;
      filterMachines = kind: machine: (import (./machines + "/${machine}")).type == kind;
      isDarwin = filterMachines "darwin";
      isNixOS = filterMachines "nixos";

      inherit (builtins) filter attrNames listToAttrs;
    in
    (
      {
        darwinConfigurations =
          let
            darwinMachines = filter (isDarwin) (attrNames machines);
          in
          listToAttrs (
            map (machine: {
              name = machine;
              value = nix-darwin.lib.darwinSystem {
                pkgs = loadPkgs "aarch64-darwin";
                modules = [
                  ./modules
                  machines."${machine}".config
                ];
              };
            }) darwinMachines
          );

        nixosConfigurations =
          let
            nixosMachines = filter isNixOS (attrNames machines);
          in
          listToAttrs (
            map (machine: {
              name = machine;
              value = nixpkgs.lib.nixosSystem {
                pkgs = loadPkgs "x86_64-linux";
                modules = [
                  ./modules
                  machines."${machine}".config
                ];
              };
            }) nixosMachines
          );
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
