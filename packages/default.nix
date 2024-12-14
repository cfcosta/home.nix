inputs: _: super: {
  dusk = {
    scripts = super.callPackage ./scripts/default.nix { };
    nightvim = inputs.neovim.packages.${super.system}.default;
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
