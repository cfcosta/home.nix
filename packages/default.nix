inputs: _: super: {
  agenix = inputs.agenix.packages.${super.system}.default;
  dusk-ai-tools = super.callPackage ./dusk-ai-tools { };
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  glimpse = inputs.glimpse.packages.${super.system}.default;
  nightvim = inputs.neovim.packages.${super.system}.default;
}
