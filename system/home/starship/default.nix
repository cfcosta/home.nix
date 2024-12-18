{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      directory.read_only = " 󰌾";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fill = {
        symbol = " ";
        style = "black";
      };
      fossil_branch.symbol = " ";
      git_branch = {
        disabled = true;
        symbol = " ";
      };
      git_commit = {
        disabled = true;
        tag_symbol = "  ";
      };
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname = {
        ssh_only = false;
        ssh_symbol = "";
        format = "[@$hostname]($style) in ";
        style = "bold blue";
      };
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell = {
        symbol = "";
        format = "[$symbol $name]($style) ";
      };
      nodejs.symbol = " ";
      ocaml.symbol = " ";
      package = {
        disabled = true;
        symbol = "󰏗 ";
      };
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      username = {
        format = "[$user]($style)";
        show_always = true;
        style_user = "bold green";
      };
      zig.symbol = " ";

      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };

      custom.jj =
        let
          jj = "${pkgs.jujutsu}/bin/jj --ignore-working-copy";
        in
        {
          command = ''
            GREEN='\033[32m'
            RED='\033[31m'
            RESET='\033[0m'
            GRAY='\033[0;90m'

            CHANGES="$(${jj} log -r@ -n1 --no-graph --color=always -T "
            separate(' $GRAY←$RESET ', change_id.shortest(4), parents.map(|p| p.change_id().shortest(3)).join(\", \"))
            ")"
            change_id="$(echo -e "$CHANGES")"

            stats=$(${jj} diff --no-pager --color=never | awk '
                /^[+]/ && !/^[+]{3}/ {ins++}
                /^[-]/ && !/^[-]{3}/ {del++}
                END {printf "%d %d", ins, del}
            ')

            # shellcheck disable=SC2086
            printf "$GREEN$RESET %s $GREEN+%d$RESET $RED-%d$RESET" "$change_id" $stats
          '';
          when = "${jj} root";
        };
    };
  };
}
