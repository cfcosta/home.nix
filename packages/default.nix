inputs: _: super:
let
  inherit (super.stdenv.hostPlatform) system;
in
{
  beads = inputs.beads.packages.${system}.default;
  claude-code = inputs.llm-agents.packages.${system}.claude-code;
  codex = inputs.llm-agents.packages.${system}.codex;
  crush = inputs.llm-agents.packages.${system}.crush;
  docbert = inputs.docbert.packages.${system}.docbert;
  docbert-cuda = inputs.docbert.packages.${system}.docbert-cuda;
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  hypr-recorder = inputs.hypr-recorder.packages.${system}.default;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;
  pi = inputs.llm-agents.packages.${system}.pi;
  pi-messenger = super.buildNpmPackage {
    pname = "pi-messenger";
    version = "v0.12.1";
    src = inputs.pi-messenger;
    npmDepsHash = "sha256-Gap1V8yElq2ydcunoLXd0DBtfuWU3WHZl1xvLYw+0QE=";
    dontNpmBuild = true;
    nativeBuildInputs = [ super.makeWrapper ];

    postInstall = ''
      mkdir -p $out/bin

      if [ ! -e "$out/bin/pi-messenger" ]; then
        ln -sf $out/lib/node_modules/pi-messenger/install.mjs $out/bin/pi-messenger
      fi

      cp -rf ${../agents}/*.md $out/lib/node_modules/pi-messenger/crew/agents/

      wrapProgram $out/bin/pi-messenger \
        --prefix PATH : ${super.lib.makeBinPath [ super.nodejs ]}
    '';

    meta.mainProgram = "pi-messenger";
  };
}
