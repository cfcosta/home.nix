inputs: _: super: {
  dusk = {
    nightvim = inputs.neovim.packages.${super.system}.default;
    refind = super.callPackage ./refind { inherit inputs; };
    waydroid-script = super.callPackage ./waydroid-script { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
