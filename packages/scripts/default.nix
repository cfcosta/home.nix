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
      deps ? (ps: [ ]),
    }:
    let
      python = python312.withPackages deps;
    in
    writeScriptBin name ''
      #!${python}/bin/python

      ${readFile file}
    '';

  ai = mkScript {
    name = "ai";
    file = ./ai.py;
    deps = ps: [
      ps.click
    ];
  };

  ai-describe = mkScript {
    name = "ai-describe";
    file = ./ai-describe.py;
    deps = ps: [
      ps.litellm
    ];
  };
in
symlinkJoin {
  name = "ai";

  paths = [
    ai
    ai-describe
  ];
}
