inputs: _: pkgs: {
  dusk = {
    catppuccin-refind = import ./refind { inherit inputs pkgs; };
    waydroid-script = import ./waydroid { inherit inputs pkgs; };
  };
}
