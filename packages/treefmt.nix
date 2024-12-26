{
  inputs,
  pkgs,
  writeTextFile,
  ...
}:
let
  styluaTOML = writeTextFile {
    name = "stylua.toml";
    text = ''
      indent_type = "Spaces"
      indent_width = 2
    '';
  };

  treefmt = inputs.treefmt-nix.lib.evalModule pkgs {
    projectRootFile = "flake.nix";

    settings = {
      allow-missing-formatter = true;
      verbose = 0;

      global.excludes = [
        "*.jpg"
        "*.lock"
        "*.png"
        "*.svg"
        "*-lock.*"
      ];

      formatter = {
        nixfmt.options = [ "--strict" ];
        shfmt.options = [
          "--ln"
          "bash"
        ];
        stylua.options = [
          "--config-path"
          styluaTOML.outPath
        ];
        prettier.excludes = [ "*.md" ];
      };
    };

    programs = {
      clang-format.enable = true;
      nixfmt.enable = true;
      prettier.enable = true;
      ruff.enable = true;
      shfmt.enable = true;
      stylua.enable = true;
      taplo.enable = true;

      rustfmt = {
        enable = true;
        package = pkgs.rust-bin.nightly.latest.default;
      };
    };
  };
in
treefmt.config.build.wrapper
