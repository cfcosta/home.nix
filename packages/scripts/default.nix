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
      deps ? (_: [ ]),
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

    ai-describe = {
      name = "ai-describe";
      file = ./ai/ai-describe;
      deps = ps: [
        ps.click
        ps.litellm
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
