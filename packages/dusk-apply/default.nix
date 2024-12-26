{
  dusk-stdlib,
  dusk-system-verify,
  writeShellApplication,
}:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "dusk-apply";

  runtimeInputs = [
    dusk-stdlib.entrypoint
    dusk-system-verify
  ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./apply.sh}
  '';
}
