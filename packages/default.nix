inputs: final: prev: {
  # A CLI Tool to generate commands using OpenAI
  # https://github.com/searchableguy/whiz
  whiz = prev.buildNpmPackage rec {
    pname = "whiz_cli";
    version = "0.0.6-alpha.0";
    src = inputs.whiz-cli;
    npmDepsHash = "sha256-NW/Sa/TSI5v/MkEUStQWkDFl0G3odWWKNswrdh50wAk=";
  };

  # A fork of todoist CLI that allows to set descriptions for tasks
  # Taken from https://github.com/sachaos/todoist/pull/238
  todoist-cli = prev.buildGoModule rec {
    pname = "todoist";
    version = "0.20.0";
    src = inputs.todoist-cli;
    vendorHash = "sha256-fWFFWFVnLtZivlqMRIi6TjvticiKlyXF2Bx9Munos8M=";
    doCheck = false;
  };
}
