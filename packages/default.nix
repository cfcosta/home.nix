inputs: _: super: {
  duskOverrides = {
    aider-chat = super.aider-chat.override {
      packageOverrides = _: super: {
        litellm =
          let
            version = "1.44.7";
          in
          super.litellm.overrideAttrs (_: {
            inherit version;

            src = super.fetchPypi {
              inherit version;

              pname = "litellm";
              hash = "sha256-yPj52ABlvoFYAlgXfzoAbehtLErx+acyrDe9MXoT8EI=";
            };
          });
      };
    };

    refind = import ./refind {
      inherit inputs;
      pkgs = super;
    };
  };

  agenix = inputs.agenix.packages.${super.system}.default;

  waydroid-script = import ./waydroid {
    inherit inputs;
    pkgs = super;
  };
}
