{
  config,
  pkgs,
  inputs,
  ...
}:
let
  pi-messenger = pkgs.buildNpmPackage {
    pname = "pi-messenger";
    version = "v0.12.1";
    src = inputs.pi-messenger;
    npmDepsHash = "sha256-Gap1V8yElq2ydcunoLXd0DBtfuWU3WHZl1xvLYw+0QE=";
    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    # Ensure binary is available and always gets a Node runtime from Nix.
    postInstall = ''
      mkdir -p $out/bin

      if [ ! -e "$out/bin/pi-messenger" ]; then
        ln -sf $out/lib/node_modules/pi-messenger/install.mjs $out/bin/pi-messenger
      fi

      cp -rf ${./agents}/*.md $out/lib/node_modules/pi-messenger/crew/agents/

      wrapProgram $out/bin/pi-messenger \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs ]}
    '';

    meta.mainProgram = "pi-messenger";
  };
in
{
  config = {
    environment.systemPackages = with pkgs; [
      beads
      claude-code
      codex
      crush
      gemini-cli
      opencode
      pi
      pi-messenger
    ];

    home-manager.users.${config.dusk.username} = _: {
      home.file.".pi/agent/settings.json".text = builtins.toJSON {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.3-codex";
        packages = [ "${inputs.pi-messenger}" ];
      };
    };
  };
}
