{
  python312,
  writeScriptBin,
}:
let
  pythonWithPackages = python312.withPackages (ps: [
    ps.litellm
  ]);
in
writeScriptBin "ai-describe" ''
  #!${pythonWithPackages}/bin/python
  ${builtins.readFile ./ai-describe.py}
''
