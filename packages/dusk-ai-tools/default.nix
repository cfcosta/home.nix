{
  python312,
  writeScriptBin,
  symlinkJoin,
}:
let
  inherit (builtins) attrValues concatMap readFile;

  python = python312.withPackages (ps: concatMap (pkg: pkg.deps ps) (attrValues packages));

  mkScript =
    { name, file, ... }:
    writeScriptBin name ''
      #!${python}/bin/python

      ${readFile file}
    '';

  packages = {
    ai-github = {
      name = "ai-github";
      file = ./ai-github.py;
      deps = ps: [
        ps.click
        ps.pydantic
        ps.rich
        ps.requests
      ];
    };
    ai-describe = {
      name = "ai-describe";
      file = ./ai-describe.py;
      deps = ps: [
        ps.click
        ps.litellm
      ];
    };
  };
in
symlinkJoin {
  name = "dusk-ai-tools";
  paths = map mkScript (attrValues packages);
  passthru = { inherit python; };
}
