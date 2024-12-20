{ config, ... }:
{
  config.programs.jujutsu = {
    enable = true;

    settings = {
      aliases = {
        xl = [
          "log"
          "-r"
          "::mine() | ::remote_bookmarks()"
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

        sync-main = [
          "rebase"
          "-s"
          "roots(main@origin)..trunk-"
          "-d"
          "main"
          "--skip-emptied"
        ];

        remotes = [
          "log"
          "-r"
          "upstreams"
        ];

        my-remotes = [
          "log"
          "-r"
          "my(upstreams)"
        ];
      };

      fix.tools.treefmt = {
        command = [
          "treefmt"
          "--no-cache"
          "-v=0"
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
          "glob:'**/*.ts'"
          "glob:'**/*.toml'"
          "glob:'**/*.tsx'"
          "glob:'**/*.sh'"
        ];
      };

      git = {
        auto-local-bookmark = true;
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
