{
  outputs =
    { nixpkgs, flake-utils, ... }:
    (
      {
        # TODO: darwinConfigurations and nixosConfigurations
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
