{ writeShellApplication, dusk }:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "dusk-system-verify";
  runtimeInputs = [ dusk.dusk-stdlib.entrypoint ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./system-verify.sh}
  '';
}
