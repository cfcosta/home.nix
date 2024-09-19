inputs: _: prev: {
  aider-chat = prev.aider-chat.overrideAttrs (_: {
    litellm =
      let
        version = "1.44.7";
      in
      prev.python3Packages.litellm.overrideAttrs (_: {
        inherit version;

        src = prev.fetchPypi {
          inherit version;

          pname = "litellm";
          hash = "sha256-yPj52ABlvoFYAlgXfzoAbehtLErx+acyrDe9MXoT8EI=";
        };
      });
  });

  agenix = inputs.agenix.packages.${prev.system}.default;

  catppuccin-refind = import ./refind {
    inherit inputs;
    pkgs = prev;
  };

  waydroid-script = import ./waydroid {
    inherit inputs;
    pkgs = prev;
  };
}
