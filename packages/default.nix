inputs: final: prev: {
  dusk = {
    inherit inputs;

    fonts = [ inputs.fonts-console-neue ];
  };

  # A CLI Tool to generate commands using OpenAI
  # https://github.com/searchableguy/whiz
  whiz = prev.buildNpmPackage {
    pname = "whiz_cli";
    version = "0.0.8-alpha.0";
    src = inputs.whiz-cli;
    npmDepsHash = "sha256-dmeG6ZqUcE65hnha0BbG/xOGoUWSL0pnhh65XVgniFw";
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
