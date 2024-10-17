{
  python312,
  aider-chat,
  inputs,
}:
let
  py3 = python312.override {
    self = py3;
    packageOverrides = _: super: { tree-sitter = super.tree-sitter_0_21; };
  };

  inherit (py3.pkgs) buildPythonApplication;
in
buildPythonApplication {
  inherit (aider-chat)
    buildInputs
    meta
    pname
    version
    ;
  pyproject = true;
  src = inputs.aider-chat;
  pythonRelaxDeps = true;
  doCheck = false;

  build-system = with py3.pkgs; [ setuptools-scm ];
  dependencies = with py3.pkgs; [
    aiohappyeyeballs
    backoff
    beautifulsoup4
    configargparse
    diff-match-patch
    diskcache
    flake8
    gitpython
    grep-ast
    importlib-resources
    json5
    jsonschema
    jiter
    litellm
    networkx
    numpy
    packaging
    pathspec
    pexpect
    pillow
    playwright
    prompt-toolkit
    ptyprocess
    pypager
    pypandoc
    pyperclip
    pyyaml
    psutil
    rich
    scipy
    sounddevice
    soundfile
    streamlit
    tokenizers
    watchdog
    pydub
  ];
}
