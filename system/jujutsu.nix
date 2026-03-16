{ config, pkgs, ... }:
let
  inherit (pkgs)
    dusk-treefmt
    makeWrapper
    symlinkJoin
    writeShellApplication
    ;

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

  jjFixFormatter = writeShellApplication {
    name = "jj-fix-formatter";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.nix
      treefmt
    ];

    text = ''
      root="$1"
      path="$2"

      input_file="$(mktemp)"
      stdout_file="$(mktemp)"
      stderr_file="$(mktemp)"

      cleanup() {
        rm -f "$input_file" "$stdout_file" "$stderr_file"
      }
      trap cleanup EXIT

      cat >"$input_file"

      find_flake_dir() {
        local dir="$1"

        while true; do
          if [ -f "$dir/flake.nix" ]; then
            printf '%s\n' "$dir"
            return 0
          fi

          if [ "$dir" = "$root" ]; then
            return 1
          fi

          dir="$(dirname "$dir")"
        done
      }

      start_dir="$(dirname "$root/$path")"
      if flake_dir="$(find_flake_dir "$start_dir")"; then
        format_path="$path"

        if [ "$flake_dir" != "$root" ]; then
          flake_prefix="''${flake_dir#"$root"/}"
          format_path="''${path#"$flake_prefix"/}"
        fi

        if (
          cd "$flake_dir"
          nix \
            --option warn-dirty false \
            fmt \
            --no-write-lock-file \
            -- \
            --stdin \
            "$format_path" \
            <"$input_file" \
            >"$stdout_file" \
            2>"$stderr_file"
        ); then
          cat "$stdout_file"
          exit 0
        fi

        stderr="$(cat "$stderr_file")"
        case "$stderr" in
          *"does not provide attribute 'formatter."*)
            ;;
          *)
            if [ -n "$stderr" ]; then
              printf '%s\n' "$stderr" >&2
            fi
            exit 1
            ;;
        esac
      fi

      cd "$root"
      exec treefmt --quiet --no-cache "$path" --stdin <"$input_file"
    '';
  };
in
{
  config = {
    home = {
      file.".config/rustfmt/rustfmt.toml".text = ''
        edition = "2024"

        reorder_imports = true
        imports_granularity = "Crate"
        imports_layout = "HorizontalVertical"
        max_width = 102
        group_imports = "StdExternalCrate"
        trailing_comma = "Vertical"
        trailing_semicolon = true
      '';

      packages = with pkgs; [ jjui ];
    };

    programs.jujutsu = {
      enable = true;

      settings = {
        aliases = {
          amend = [ "squash" ];

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
            "${jjFixFormatter}/bin/jj-fix-formatter"
            "$root"
            "$path"
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
          git-push-bookmark = "\"cfcosta/\" ++ change_id.short()";
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
          behavior = "own";
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
          diff-formatter = ":git";
          editor = "nvim";
          pager = "delta";
          revsets-use-glob-by-default = true;
        };
      };
    };
  };
}
