inputs: _: prev: {
  dusk = {
    inherit inputs;
  };

  # A CLI Tool to generate commands using OpenAI
  # https://github.com/searchableguy/whiz
  whiz = prev.buildNpmPackage rec {
    pname = "whiz_cli";
    version = "0.0.8-alpha.0";
    src = inputs.whiz-cli;
    npmDepsHash = "sha256-dmeG6ZqUcE65hnha0BbG/xOGoUWSL0pnhh65XVgniFw";
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

  # A CLI tool to control the clipboard using the OSC 52 escape sequences
  osc = prev.buildGoModule rec {
    pname = "osc";
    version = "0.3.5";
    src = inputs.osc;
    vendorHash = "sha256-J4b1ajlBKZYBHWuaUb0dvm1MqqbPPTsmtau+c3wTBQI=";
    doCheck = false;
  };
}
