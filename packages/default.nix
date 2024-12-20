inputs: _: super: rec {
  dusk = {
    nightvim = inputs.neovim.packages.${super.system}.default;

    dusk-apply = super.callPackage ./dusk-apply { };
    dusk-jujutsu = super.callPackage ./dusk-jujutsu { };
    dusk-stdlib = super.callPackage ./dusk-stdlib { };
    dusk-system-verify = super.callPackage ./dusk-system-verify { inherit dusk; };
    dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
