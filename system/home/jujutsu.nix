{
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs) writeTextFile;

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
      global.excludes = [
        "*.jpg"
        "*.lock"
        "*.png"
        "*.svg"
        "*-lock.*"
      ];

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
{
  config = {
    home.packages = [ treefmt.config.build.wrapper ];

    programs.jujutsu = {
      enable = true;

      settings = {
        aliases = {
          xl = [
            "log"
            "-r"
            "::mine()"
          ];

          prs-update-trunk = [
            "rebase"
            "-s"
            "trunk_commit"
            "-d"
            "main"
            "-d"
            "all:heads(clean_prs | my_prs)"
            "--skip-emptied"
          ];

          sync-main = [
            "rebase"
            "-s"
            "roots(main@origin)..trunk_commit-"
            "-d"
            "main"
            "--skip-emptied"
          ];

          prs = [
            "log"
            "-r"
            "all_prs"
          ];

          my-prs = [
            "log"
            "-r"
            "my_prs"
          ];
        };

        fix.tools.treefmt = {
          command = [
            "treefmt-nix"
            "--stdin"
            "$path"
          ];

          patterns = [
            "glob:'**/*.js'"
            "glob:'**/*.jsx'"
            "glob:'**/*.lua'"
            "glob:'**/*.nix'"
            "glob:'**/*.py'"
            "glob:'**/*.rs'"
            "glob:'**/*.ts'"
            "glob:'**/*.toml'"
            "glob:'**/*.tsx'"
            "glob:'**/*.sh'"
          ];
        };

        git = {
          auto-local-bookmark = true;
          private-commits = "private_commits | trunk_commit";
          push-bookmark-prefix = "${config.dusk.accounts.github}/";
        };

        revset-aliases = {
          all_prs = ''
            bookmarks(glob:"pr/*") ~ ::main@origin
          '';

          clean_prs = "all_prs ~ conflicts()";
          broken_prs = "all_prs & conflicts()";

          my_prs = "all_prs & mine()";
          other_prs = "all_prs & mine()";
          private_commits = "description(glob:'wip:*') | description(glob:'private:*')";
          trunk_commit = "description(glob:'trunk:*') & mine()";
        };

        snapshot.max-new-file-size = "10MiB";

        signing = {
          sign-all = true;
          backend = "gpg";
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.username()";
          "format_short_id(id)" = "id.shortest()";
        };

        user = {
          inherit (config.dusk) name;
          email = config.dusk.emails.primary;
        };

        ui = {
          default-command = [ "status" ];
          diff-editor = ":builtin";
          diff.format = "git";
          editor = "nvim";
          pager = "delta";
        };
      };
    };
  };
}
