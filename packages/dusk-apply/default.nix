{ writeShellApplication, dusk }:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "dusk-apply";

  runtimeInputs = [
    dusk.dusk-stdlib.entrypoint
    dusk.dusk-system-verify
  ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./apply.sh}
  '';
}
