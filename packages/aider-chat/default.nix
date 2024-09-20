{
  aider-chat,
  inputs,
  portaudio,
  python311,
}:

let
  python3 = python311.override {
    self = python3;
    packageOverrides = _: super: { tree-sitter = super.tree-sitter_0_21; };
  };

  litellm =
    let
      version = "1.44.7";
    in
    python3.pkgs.litellm.overrideAttrs (_: {
      inherit version;

      src = python3.pkgs.fetchPypi {
        inherit version;

        pname = "litellm";
        hash = "sha256-yPj52ABlvoFYAlgXfzoAbehtLErx+acyrDe9MXoT8EI=";
      };
    });
in
python3.pkgs.buildPythonApplication {
  inherit (aider-chat) meta version;

  pname = "aider-chat";
  pyproject = true;

  src = inputs.aider-chat;

  pythonRelaxDeps = true;

  build-system = with python3.pkgs; [ setuptools-scm ];

  dependencies =
    [ litellm ]
    ++ (with python3.pkgs; [
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
      jiter
      json5
      jsonschema
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
      rich
      scipy
      sounddevice
      soundfile
      streamlit
      tokenizers
      watchdog
      psutil
    ]);

  buildInputs = [ portaudio ];

  doCheck = false;
}
