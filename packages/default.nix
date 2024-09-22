inputs: _: super: {
  dusk = {
    refind = super.callPackage ./refind { inherit inputs; };
    waydroid-script = super.callPackage ./waydroid-script { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
