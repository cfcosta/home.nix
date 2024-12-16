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
    ai-describe = {
      name = "jj-ai-describe";
      file = ./jj-ai-describe;
      deps = ps: [
        ps.click
        ps.litellm
      ];
    };
  };
in
symlinkJoin {
  name = "dusk-jujutsu";
  paths = map mkScript (attrValues packages);
  passthru = { inherit python; };
}
