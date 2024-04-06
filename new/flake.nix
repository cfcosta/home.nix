{
  outputs =
    { nixpkgs, flake-utils, ... }:
    (
      {
        darwinConfigurations = {
          # Add your Darwin configurations here
        };

        nixosConfigurations = {
          battlecruiser = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./machines/battlecruiser.nix ];
          };
        };
      }
      // flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
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
