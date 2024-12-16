{
  callPackage,
  lib,
  symlinkJoin,
  writeShellApplication,
}:
let
  inherit (builtins) attrValues concatStringsSep;

  namespace = "dusk-stdlib";

  entrypoint =
    let
      destinations = map (p: "${p}/${p.destination}") (attrValues packages);
      load = dest: ''echo ". ${dest}"'';
    in
    writeShellApplication {
      name = "dusk-stdlib-load";
      text = ''
        ${concatStringsSep "\n" (map load destinations)}
      '';
    };

  packages = {
    log = (callPackage ./log { inherit namespace; });
  };
in
symlinkJoin {
  name = namespace;

  paths = (attrValues packages) ++ [ entrypoint ];
  passthru = packages // {
    inherit entrypoint;
  };

  meta = with lib; {
    description = "A much needed standard library for the Bourne Again Shell";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
