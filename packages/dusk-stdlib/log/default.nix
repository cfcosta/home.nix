{ writeTextFile, namespace }:
let
  inherit (builtins) readFile;
  destination = "/share/${namespace}/log.sh";
in
writeTextFile {
  inherit destination;

  name = "${namespace}-log";
  text = readFile ./log.sh;

  passthru = { inherit destination; };
}
