inputs: _: pkgs: {
  agenix = inputs.agenix.packages.${pkgs.system}.default;

  catppuccin-refind = import ./refind { inherit inputs pkgs; };
  waydroid-script = import ./waydroid { inherit inputs pkgs; };
}
