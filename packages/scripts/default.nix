{
  python312,
  writeScriptBin,
  symlinkJoin,
}:
let
  inherit (builtins) attrValues concatMap;

  python = python312.withPackages (ps: concatMap (pkg: pkg.deps ps) (attrValues packages));

  mkScript =
    {
      name,
      file,
      ...
    }:
    writeScriptBin name file;

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
        ps.litellm
      ];
    };

    ai-get-github = {
      name = "ai-github";
      file = ./ai/ai-get-github;
      deps = ps: [
        ps.click
        ps.requests
        ps.pydantic
      ];
    };
  };
in
{
  inherit python;

  ai = symlinkJoin {
    name = "ai";
    paths = map mkScript (attrValues packages);
  };
}
