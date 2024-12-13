{
  python312,
  writeScriptBin,
  symlinkJoin,
}:
let
  inherit (builtins) attrValues concatMap;

  python = python312.withPackages (ps: concatMap (pkg: pkg.deps ps) (attrValues packages));

  inherit (builtins) readFile;

  mkScript =
    {
      name,
      file,
      deps ? (ps: [ ]),
    }:
    let
      python = python312.withPackages deps;
    in
    writeScriptBin name ''
      #!${python}/bin/python

      ${readFile file}
    '';

  packages = {
    ai = {
      name = "ai";
      file = ./ai/ai;
      deps = ps: [
        ps.click
      ];
    };
  };
in
{
  inherit python;

  all = symlinkJoin {
    name = "dusk-scripts";
    paths = map mkScript (attrValues packages);
  };
}
