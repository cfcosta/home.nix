inputs: _: pkgs: {
  dusk.waydroid-script = import ./waydroid { inherit inputs pkgs; };
}
