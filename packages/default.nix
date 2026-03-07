inputs: _: super:
let
  inherit (super.stdenv.hostPlatform) system;
  inherit (inputs.docbert.packages.${system}) docbert docbert-cuda;
  inherit (inputs.llm-agents.packages.${system})
    claude-code
    codex
    crush
    pi
    ;
  beads = inputs.beads.packages.${system}.default;
in
{
  inherit
    beads
    docbert
    docbert-cuda
    claude-code
    codex
    crush
    pi
    ;
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-skills = inputs.dusk-skills.packages.${system}.default;
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  hypr-recorder = inputs.hypr-recorder.packages.${system}.default;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;
  inherit (inputs.dusk-skills.packages.${system}) pi-bug-fix pi-owasp-fix pi-test-audit;
}
