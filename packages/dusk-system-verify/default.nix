{ writeShellApplication, dusk-stdlib }:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "dusk-system-verify";
  runtimeInputs = [ dusk-stdlib.entrypoint ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./system-verify.sh}
  '';
}
