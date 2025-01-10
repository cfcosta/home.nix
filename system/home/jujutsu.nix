{ config, pkgs, ... }:
let
  inherit (pkgs) dusk-treefmt makeWrapper symlinkJoin;

  treefmt = symlinkJoin {
    name = "jujutsu-treefmt";
    paths = [ dusk-treefmt ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/treefmt \
        --set NO_COLOR 1 \
        --set TREEFMT_VERBOSE 0
    '';
  };
in
{
  config = {
    home.file.".config/rustfmt/rustfmt.toml".text = ''
      edition = "2024"

      reorder_imports = true
      imports_granularity = "Crate"
      imports_layout = "HorizontalVertical"
      max_width = 102
      group_imports = "StdExternalCrate"
      trailing_comma = "Vertical"
      trailing_semicolon = true
    '';

    programs.jujutsu = {
      enable = true;

      settings = {
        aliases = {
          ai-describe = [
            "util"
            "exec"
            "--"
            "${pkgs.dusk-ai-tools}/bin/ai-describe"
          ];
          my-remotes = [
            "log"
            "-r"
            "my(upstreams)"
          ];
          remotes = [
            "log"
            "-r"
            "upstreams"
          ];
          sync-main = [
            "rebase"
            "-s"
            "roots(main@origin)..trunk-"
            "-d"
            "main"
            "--skip-emptied"
          ];
          update-trunk = [
            "rebase"
            "-s"
            "trunk"
            "-d"
            "main"
            "-d"
            "all:heads(my(upstreams))"
            "--skip-emptied"
          ];
          xl = [
            "log"
            "-r"
            "::mine() | ::remote_bookmarks()"
          ];
        };

        fix.tools.treefmt = {
          command = [
            "${treefmt}/bin/treefmt"
            "--no-cache"
            "$path"
            "--stdin"
          ];

          patterns = [
            "glob:'**/*.js'"
            "glob:'**/*.jsx'"
            "glob:'**/*.lua'"
            "glob:'**/*.nix'"
            "glob:'**/*.py'"
            "glob:'**/*.rs'"
            "glob:'**/*.sh'"
            "glob:'**/*.toml'"
            "glob:'**/*.ts'"
            "glob:'**/*.tsx'"
          ];
        };

        git = {
          private-commits = "private | trunk";
          push-bookmark-prefix = "${config.dusk.accounts.github}/";
        };

        revset-aliases = {
          upstreams = ''
            tracked_remote_bookmarks() ~ ::main@origin
          '';

          "clean(a)" = "a ~ conflicts()";
          "broken(a)" = "a & conflicts()";
          "my(a)" = "a & mine()";

          private = "description(glob:'wip:*') | description(glob:'private:*') | trunk::";
          trunk = ''bookmarks("trunk") & mine()'';
        };

        snapshot.max-new-file-size = "10MiB";

        signing = {
          sign-all = true;
          backend = "gpg";
        };

        template-aliases = {
          "format_short_signature(signature)" = "signature.email()";
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
