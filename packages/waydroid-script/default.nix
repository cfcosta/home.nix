{
  inputs,
  lib,
  lzip,
  python3Packages,
  stdenv,
  substituteAll,
  util-linux,
}:
let
  inherit (builtins) replaceStrings;
  inherit (lib.strings) removePrefix;
  inherit (stdenv) mkDerivation;
  inherit (python3Packages)
    buildPythonApplication
    inquirerpy
    requests
    tqdm
    ;

  pname = "waydroid-script";
  version = "0.0.0";
  src = inputs.waydroid-script;

  resetprop = mkDerivation {
    inherit version src;
    pname = "resetprop";

    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share
      cp -r bin/* $out/share/
    '';
  };
in
buildPythonApplication rec {
  inherit pname version src;

  propagatedBuildInputs = [
    lzip
    util-linux

    inquirerpy
    requests
    tqdm
  ];

  postPatch =
    let
      setup = substituteAll {
        inherit pname;
        desc = "Python Script to add libraries to waydroid";

        src = ./setup.py;

        version = replaceStrings [ "-" ] [ "." ] (removePrefix "0-unstable-" version);
      };
    in
    ''
      ln -s ${setup} setup.py

      substituteInPlace stuff/general.py \
        --replace-fail "os.path.dirname(__file__), \"..\", \"bin\"," "\"${resetprop}/share\","
    '';
}
