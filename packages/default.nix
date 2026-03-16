inputs: _: super:
let
  inherit (super.stdenv.hostPlatform) system;
in
{
  inherit (inputs.docbert.packages.${system}) docbert docbert-cuda;
  inherit (inputs.llm-agents.packages.${system}) claude-code codex crush;

  beads = inputs.beads.packages.${system}.default;
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  duskpi = inputs.duskpi.packages.${system}.default;
  hypr-recorder = inputs.hypr-recorder.packages.${system}.default;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;
}
