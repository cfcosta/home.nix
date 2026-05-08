{
  bun2nix,
  lib,
  runCommand,
  src,
}:
let
  version = (lib.importJSON "${src}/package.json").version;

  bunNix = runCommand "hunk-bun.nix" { nativeBuildInputs = [ bun2nix ]; } ''
    bun2nix --lock-file ${src}/bun.lock --copy-prefix "${src}/" --output-file $out
  '';
in
bun2nix.mkDerivation {
  pname = "hunk";
  inherit version src;

  bunDeps = bun2nix.fetchBunDeps { inherit bunNix; };

  module = "src/main.tsx";
  bunCompileToBytecode = false;

  dontStrip = true;

  meta = {
    description = "Review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = lib.platforms.unix;
  };
}
