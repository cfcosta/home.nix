final: prev: {
  # A CLI Tool to generate commands using OpenAI
  # https://github.com/searchableguy/whiz
  whiz = prev.buildNpmPackage rec {
    pname = "whiz_cli";
    version = "0.0.6-alpha.0";

    src = prev.fetchFromGitHub {
      owner = "searchableguy";
      repo = "whiz";
      rev = "249c2045e3ba81d1a9cda1d9c3a670c7767df69c";
      hash = "sha256-cgSFhAKwwE2fzr4Bl5Fw1agmAoa/ySgt4j/f/NY46ZY=";
    };

    npmDepsHash = "sha256-NW/Sa/TSI5v/MkEUStQWkDFl0G3odWWKNswrdh50wAk=";
  };

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
