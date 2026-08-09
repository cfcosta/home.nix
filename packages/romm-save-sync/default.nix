{ python3, writeTextFile }:
let
  inherit (builtins) readFile;
in
writeTextFile {
  name = "romm-save-sync";
  destination = "/bin/romm-save-sync";
  executable = true;

  # Stdlib only (urllib/zipfile/hashlib), so the closure is just the
  # interpreter. This runs from a timer every few minutes; there is no reason
  # for it to drag an HTTP library along for one POST and two GETs.
  text = ''
    #!${python3.interpreter}
    ${readFile ./sync.py}
  '';

  # Catch a syntax error at build time rather than in the journal on the next
  # timer tick. `ast.parse` rather than `py_compile`, which would litter the
  # output with a __pycache__ directory.
  checkPhase = ''
    ${python3.interpreter} -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' \
      "$out/bin/romm-save-sync"
  '';

  meta.mainProgram = "romm-save-sync";
}
