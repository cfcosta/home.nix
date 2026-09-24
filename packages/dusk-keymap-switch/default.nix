{
  dusk-stdlib,
  writeShellApplication,
  hyprland,
  jq,
}:
let
  inherit (builtins) readFile;
in
writeShellApplication {
  name = "dusk-keymap-switch";

  runtimeInputs = [
    dusk-stdlib.entrypoint
    hyprland
    jq
  ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./keymap-switch.sh}
  '';
}
