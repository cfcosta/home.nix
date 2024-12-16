inputs: _: super: rec {
  dusk = {
    nightvim = inputs.neovim.packages.${super.system}.default;
    dusk-jujutsu = super.callPackage ./dusk-jujutsu { };
    dusk-apply = super.callPackage ./dusk-apply { };
    dusk-stdlib = super.callPackage ./dusk-stdlib { };
    dusk-system-verify = super.callPackage ./dusk-system-verify { inherit dusk; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
