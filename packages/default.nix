inputs: _: super:
let
  inherit (super.stdenv.hostPlatform) system;
in
{
  beads = inputs.beads.packages.${system}.default;
  docbert = inputs.docbert.packages.${system}.docbert;
  docbert-cuda = inputs.docbert.packages.${system}.docbert-cuda;
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  hypr-recorder = inputs.hypr-recorder.packages.${system}.default;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;
}
