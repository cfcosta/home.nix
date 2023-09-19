final: prev: {
  # A fork of todoist CLI that allows to set descriptions for tasks
  # Taken from https://github.com/sachaos/todoist/pull/238
  todoist-cli = prev.buildGoModule rec {
    pname = "todoist";
    version = "0.20.0";
    src = prev.fetchFromGitHub {
      owner = "psethwick";
      repo = "todoist";
      rev = "2f80bdc65de44581c4497107a092c73f39ae0b62";
      sha256 = "sha256-cFnGIJty0c4iOMNeMt+pev75aWcd7HKkvVowd5XbsXs=";
    };
    vendorHash = "sha256-fWFFWFVnLtZivlqMRIi6TjvticiKlyXF2Bx9Munos8M=";
    doCheck = false;
  };
}
