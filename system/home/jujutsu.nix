{
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs) writeTextFile;
  inherit (inputs.nix-std.lib.serde) toTOML;

  rustfmtConfig = writeTextFile {
    name = "rustfmt.toml";
    text = toTOML {
      reorder_imports = true;
      imports_granularity = "Crate";
      imports_layout = "HorizontalVertical";
      max_width = 80;
      group_imports = "StdExternalCrate";
      trailing_comma = "Vertical";
      trailing_semicolon = true;
    };
  };
in
{
  config.programs.jujutsu = {
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

      fix.tools = {
        clang-format = {
          command = [
            "${pkgs.clang-tools}/bin/clang-format"
            "--sort-includes"
            "--assume-filename=$path"
          ];
          patterns = [
            "glob:'**/*.c'"
            "glob:'**/*.h'"
          ];
        };

        nixfmt = {
          command = [
            "${pkgs.nixfmt-rfc-style}/bin/nixfmt"
            "--strict"
            "--filename=$path"
          ];
          patterns = [ "glob:'**/*.nix'" ];
        };

        ruff = {
          command = [
            "${pkgs.ruff}/bin/ruff"
            "format"
            "--stdin-filename"
            "$path"
          ];
          patterns = [ "glob:'**/*.py'" ];
        };

        rustfmt = {
          command = [
            "${pkgs.rust-bin.nightly.latest.default}/bin/rustfmt"
            "--config-path"
            "${rustfmtConfig.outPath}"
            "--emit"
            "stdout"
          ];
          patterns = [ "glob:'**/*.rs'" ];
        };

        shfmt = {
          command = [
            "${pkgs.shfmt}/bin/shfmt"
            "--ln"
            "bash"
            "-s"
            "-"
          ];
          patterns = [ "glob:'**/*.sh'" ];
        };

        taplo = {
          command = [
            "${pkgs.taplo}/bin/taplo"
            "fmt"
            "--stdin-filepath=$path"
            "-"
          ];
          patterns = [ "glob:**/*.toml" ];
        };
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
}
