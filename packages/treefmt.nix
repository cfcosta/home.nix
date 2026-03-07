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
        "*-lock.*"
        "*.age"
        "*.jpg"
        "*.lock"
        "*.md"
        "*.png"
        "*.svg"
        "*ignore"
        ".envrc"
      ];

      formatter = {
        nixfmt.options = [ "--strict" ];
        rustfmt.options = [
          "--config"
          "reorder_imports=true,imports_granularity=Crate,imports_layout=HorizontalVertical,max_width=80,group_imports=StdExternalCrate,trailing_comma=Vertical,trailing_semicolon=true"
        ];
        shfmt.options = [
          "--ln"
          "bash"
        ];
        stylua.options = [
          "--config-path"
          styluaTOML.outPath
        ];
      };
    };

    programs = {
      clang-format.enable = true;
      deadnix.enable = true;
      nixfmt.enable = true;
      oxfmt.enable = true;
      ruff-format.enable = true;
      ruff.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
      stylua.enable = true;
      taplo.enable = true;

      rustfmt = {
        enable = true;

        package = pkgs.rust-bin.nightly.latest.default.overrideAttrs (oldAttrs: {
          meta = oldAttrs.meta // {
            mainProgram = "rustfmt";
          };
        });
      };
    };
  };
in
treefmt.config.build.wrapper
