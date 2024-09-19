inputs: _: final: {
  agenix = inputs.agenix.packages.${final.system}.default;

  catppuccin-refind = import ./refind {
    inherit inputs;
    pkgs = final;
  };

  python3Packages = final.python3Packages // {
    litellm =
      let
        version = "v1.44.7";
      in
      final.litellm.overrideAttrs (_: {
        inherit version;

        src = final.fetchPypi {
          inherit version;

          pname = "litellm";
          hash = "";
        };
      });
  };

  waydroid-script = import ./waydroid {
    inherit inputs;
    pkgs = final;
  };
}
