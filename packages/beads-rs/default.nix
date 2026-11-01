{
  src,
  perl,
  pkg-config,
  rustPlatform,
  sqlite,
}:
rustPlatform.buildRustPackage {
  pname = "beads-rs";
  version = "0.2.0-alpha.1";

  inherit src;
  cargoLock.lockFile = "${src}/Cargo.lock";

  # Only `bd` itself. The rest of the workspace (fuzz, stateright models) is
  # development tooling, and the crate's other binary, tailnet_proxy, has no
  # business on PATH.
  cargoBuildFlags = [
    "--package"
    "beads-rs"
    "--bin"
    "bd"
  ];

  # git2 is built with vendored libgit2 and OpenSSL, and OpenSSL's configure
  # is a Perl script.
  nativeBuildInputs = [
    perl
    pkg-config
  ];

  # rusqlite is not built with `bundled`, so it links the system SQLite.
  buildInputs = [ sqlite ];

  # The test suite spins up daemons and git repos under $HOME; not worth
  # fighting the sandbox for a CLI we only consume.
  doCheck = false;

  meta.mainProgram = "bd";
}
