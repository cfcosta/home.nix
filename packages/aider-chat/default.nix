{
  aider-chat,
  inputs,
  portaudio,
  python311,
}:

let
  python3 = python311.override {
    self = python3;
    packageOverrides = _: super: {
      inherit litellm;

      tree-sitter = super.tree-sitter_0_21;
    };
  };

  litellm =
    let
      version = "1.44.7";
    in
    python311.pkgs.buildPythonApplication {
      pname = "litellm";
      inherit version;
      pyproject = true;

      src = python3.pkgs.fetchPypi {
        inherit version;

        pname = "litellm";
        hash = "sha256-yPj52ABlvoFYAlgXfzoAbehtLErx+acyrDe9MXoT8EI=";
      };
    };
in
python3.pkgs.buildPythonApplication {
  inherit (aider-chat) meta version;

  pname = "aider-chat";
  pyproject = true;

  src = inputs.aider-chat;

  pythonRelaxDeps = true;

  build-system = with python3.pkgs; [ setuptools-scm ];

  dependencies = [ litellm ];

  buildInputs = [ portaudio ];

  doCheck = false;
}
