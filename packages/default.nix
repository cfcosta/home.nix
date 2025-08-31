inputs: _: super: {
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  glimpse = inputs.glimpse.packages.${super.system}.default;
  nightvim = inputs.neovim.packages.${super.system}.default;
  nm-wifi = inputs.nm-wifi.packages.${super.system}.default;
}
