{
  python312,
  writeScriptBin,
  symlinkJoin,
}:
let
  inherit (builtins) readFile;

  mkScript =
    {
      name,
      file,
      deps ? [ ],
    }:
    let
      python = python312.withPackages deps;
    in
    writeScriptBin name ''
      #!${python}/bin/python

      ${readFile file}
    '';

  ai-describe = mkScript {
    name = "ai-describe";
    file = ./ai-describe.py;
    deps = ps: [
      ps.litellm
    ];
  };
in
symlinkJoin {
  name = "dusk-scripts";
  paths = [
    ai-describe
  ];
}
