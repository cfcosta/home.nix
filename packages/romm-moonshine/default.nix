{ python3, runCommand }:
runCommand "romm-moonshine" { meta.mainProgram = "romm-moonshine"; } ''
  cp ${./sync.py} sync.py
  cp ${./test_sync.py} test_sync.py
  ${python3.interpreter} -m unittest -v
  mkdir -p "$out/bin"
  echo '#!${python3.interpreter}' > "$out/bin/romm-moonshine"
  cat sync.py >> "$out/bin/romm-moonshine"
  chmod +x "$out/bin/romm-moonshine"
''
