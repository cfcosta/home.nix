inputs: _: super:
let
  inherit (super) lib;
  inherit (super.stdenv.hostPlatform) isLinux system;
in
{
  inherit (inputs.docbert.packages.${system}) docbert docbert-cuda;
  inherit (inputs.llm-agents.packages.${system}) claude-code codex;

  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  duskpi = inputs.duskpi.packages.${system}.default;
  hyprland = inputs.hyprland.packages.${system}.hyprland;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;
  romm-save-sync = super.callPackage ./romm-save-sync { };
}
// lib.optionalAttrs isLinux {
  inherit (inputs.codex-desktop-linux.packages.${system}) codex-desktop;
}
