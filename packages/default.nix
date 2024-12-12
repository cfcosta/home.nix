inputs: _: super: {
  dusk = {
    scripts = super.callPackage ./scripts/default.nix { };
    nightvim = inputs.neovim.packages.${super.system}.default;
    refind = super.callPackage ./refind { inherit inputs; };
    waydroid-script = super.callPackage ./waydroid-script { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
