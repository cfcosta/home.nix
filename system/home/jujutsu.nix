{ config, pkgs, ... }:
{
  config.programs.jujutsu = {
    enable = true;

    settings = {
      aliases = {
        xl = [
          "log"
          "-r"
          "all()"
        ];

        sync = [
          "rebase"
          "-s"
          "dev"
          "-d"
          "main"
          "-d"
          "all:heads(roots(remote_bookmarks()+::)..(description(glob:'wip:*') | description(glob:'private:*'))-)"
          "--skip-emptied"
        ];
      };

      fix.tools = {
        clang-format = {
          command = [
            "${pkgs.clang-tools}/clang-format"
            "--sort-includes"
            "--assume-filename=$path"
          ];

          patterns = [
            "glob:'**/*.c'"
            "glob:'**/*.h'"
          ];
        };

        rustfmt = {
          command = [
            "${pkgs.rustfmt}/rustfmt"
            "$path"
          ];

          patterns = [
            "glob:'**/*.rs'"
          ];
        };
      };

      git = {
        auto-local-bookmark = true;
        private-commits = "description(glob:'wip:*') | description(glob:'private:*')";
        push-bookmark-prefix = "${config.dusk.accounts.github}/";
      };

      revsets.log = "main-..mine() | bookmarks()";
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
