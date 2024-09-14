{ inputs, pkgs }:
let
  inherit (pkgs.stdenvNoCC) mkDerivation;
in
mkDerivation {
  pname = "catppuccin-refind";
  src = inputs.catppuccin-refind;
  version = inputs.catppuccin-refind.shortRev or inputs.catppuccin-refind.lastModifiedDate;

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/refind/themes/catppuccin

    cp -rf * $out/share/refind/themes/catppuccin
    cp -rf ${pkgs.refind}/* $out/

    chmod +w $out/share/refind/refind.conf-sample
    echo -e "\ninclude themes/catppuccin/mocha.conf" >> $out/share/refind/refind.conf-sample
    chmod -w $out/share/refind/refind.conf-sample
  '';
}
