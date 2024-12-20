{
  inputs,
  pkgs,
  writeTextFile,
  ...
}:
let
  rustfmtTOML = writeTextFile {
    name = "rustfmt.toml";
    text = ''
      edition = "2024"
      reorder_imports = true
      imports_granularity = "Crate"
      imports_layout = "HorizontalVertical"
      max_width = 102
      group_imports = "StdExternalCrate"
      trailing_comma = "Vertical"
      trailing_semicolon = true
    '';
  };

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
      global = {
        allow_missing_formatter = true;
        verbose = 0;

        excludes = [
          "*.jpg"
          "*.lock"
          "*.png"
          "*.svg"
          "*-lock.*"
        ];
      };

      formatter = {
        nixfmt.options = [ "--strict" ];
        rustfmt.options = [
          "--config-path"
          rustfmtTOML.outPath
        ];
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
