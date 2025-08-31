{
  dusk-stdlib,
  writeShellApplication,
  hyprland,
  jq,
  libnotify,
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
    libnotify
  ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./keymap-switch.sh}
  '';
}
