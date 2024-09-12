{
  pkgs,
  ...
}:
let
  pname = "waydroid-script";
  version = "0-unstable-2024-01-20";
  src = pkgs.fetchFromGitHub {
    repo = "waydroid_script";
    owner = "casualsnek";
    rev = "1a2d3ad643206ad5f040e0155bb7ab86c0430365";
    hash = "sha256-OiZO62cvsFyCUPGpWjhxVm8fZlulhccKylOCX/nEyJU=";
  };

  resetprop = pkgs.stdenv.mkDerivation {
    pname = "resetprop";
    inherit version src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share
      cp -r bin/* $out/share/
    '';
  };
in
pkgs.python3Packages.buildPythonApplication rec {
  inherit pname version src;

  propagatedBuildInputs = with pkgs; [
    python3Packages.inquirerpy
    python3Packages.requests
    python3Packages.tqdm

    lzip
    util-linux
  ];

  postPatch =
    let
      setup = pkgs.substituteAll {
        src = ./setup.py;
        inherit pname;
        desc = "Python Script to add libraries to waydroid";
        version = builtins.replaceStrings [ "-" ] [ "." ] (
          pkgs.lib.strings.removePrefix "0-unstable-" version
        );
      };
    in
    ''
      ln -s ${setup} setup.py

      substituteInPlace stuff/general.py \
        --replace-fail "os.path.dirname(__file__), \"..\", \"bin\"," "\"${resetprop}/share\","
    '';

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [ "--version=branch" ];
  };
}
