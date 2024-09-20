{ pkgs, inputs }:
pkgs.fava.overrideAttrs {
  src = inputs.fava;

  nativeBuildInputs = [
    pkgs.nodejs
    pkgs.nodePackages.esbuild
  ];

  patches = [ ./catppuccin.patch ];
}
