inputs: final: super:
let
  inherit (super.stdenv.hostPlatform) system;
in
{
  dusk-apply = super.callPackage ./dusk-apply { };
  dusk-keymap-switch = super.callPackage ./dusk-keymap-switch { };
  dusk-stdlib = super.callPackage ./dusk-stdlib { };
  dusk-system-verify = super.callPackage ./dusk-system-verify { };
  dusk-treefmt = super.callPackage ./treefmt.nix { inherit inputs; };
  hypr-recorder = inputs.hypr-recorder.packages.${system}.default;
  nightvim = inputs.neovim.packages.${system}.default;
  nm-wifi = inputs.nm-wifi.packages.${system}.default;

  beads = inputs.beads.packages.${system}.default;
  gas-town = super.buildGoModule {
    pname = "gas-town";
    version = "0.5.0";

    src = inputs.gas-town;

    nativeBuildInputs = with super; [
      makeWrapper
      installShellFiles
    ];

    buildPhase = ''
      make build
    '';

    installPhase = ''
      mkdir -p $out/bin
      mv gt $out/bin
    '';

    # Wrap the binary to ensure runtime dependencies are available
    postInstall = ''
      wrapProgram $out/bin/gt \
        --prefix PATH : ${
          with super;
          lib.makeBinPath ([
            final.beads
            tmux
            git
          ])
        }

      # Generate shell completions
      installShellCompletion --cmd gt \
        --bash <($out/bin/gt completion bash) \
        --fish <($out/bin/gt completion fish) \
        --zsh <($out/bin/gt completion zsh)
    '';

    vendorHash = "sha256-ripY9vrYgVW8bngAyMLh0LkU/Xx1UUaLgmAA7/EmWQU=";
    doCheck = false;

    meta = {
      description = "Multi-agent workspace manager";
      homepage = "https://github.com/steveyegge/gastown";
      license = super.lib.licenses.mit;
    };
  };
}
