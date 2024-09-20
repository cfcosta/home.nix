inputs: _: super:
let
  inherit (super) callPackage;
in
{
  dusk = {
    aider-chat = callPackage ./aider-chat { inherit inputs; };
    refind = callPackage ./refind { inherit inputs; };
    waydroid-script = callPackage ./waydroid-script { inherit inputs; };
  };

  agenix = inputs.agenix.packages.${super.system}.default;
}
