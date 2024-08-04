inputs: final: prev: {
  dusk = {
    inherit inputs;
  };

  # A fork of todoist CLI that allows to set descriptions for tasks
  # Taken from https://github.com/sachaos/todoist/pull/238
  todoist-cli = prev.buildGoModule {
    pname = "todoist";
    version = "0.20.0";
    src = inputs.todoist-cli;
    vendorHash = "sha256-fWFFWFVnLtZivlqMRIi6TjvticiKlyXF2Bx9Munos8M=";
    doCheck = false;
  };
}
