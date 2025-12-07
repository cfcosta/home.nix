{
  dusk-stdlib,
  writeShellApplication,
  fcitx5,
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
    fcitx5
    hyprland
    jq
  ];

  text = ''
    eval "$(dusk-stdlib-load)"

    ${readFile ./keymap-switch.sh}
  '';
}
