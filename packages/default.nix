inputs: _: super: {
  dusk = {
    aider-chat = super.callPackage ./aider-chat.nix { inherit inputs; };
    refind = super.callPackage ./refind { inherit inputs; };
    waydroid-script = super.callPackage ./waydroid-script { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
