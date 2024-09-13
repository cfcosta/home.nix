{ inputs, pkgs }:
let
  inherit (pkgs.stdenv) mkDerivation;
in
mkDerivation {
  pname = "catppuccin-refind";
  src = inputs.catppuccin-refind;
  version = inputs.catppuccin-refind.rev;

  dontBuild = true;

  buildInputs = [
    pkgs.efibootmgr
  ];

  installPhase = ''
    mkdir -p $out/share/refind/themes/catppuccin

    cp -rf ${pkgs.refind}/* $out/
    cp -rf * $out/share/refind/themes/catppuccin

    echo "include themes/catppuccin/mocha.conf" >> $out/share/refind/refind.conf-sample
  '';
}
