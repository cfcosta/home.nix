_: {
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
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell = {
        symbol = " ";
        impure_msg = "";
        format = "[$symbol $name]($style)";
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

      custom = {
        jj = {
          command = ''
            jj log -r@ -n1 --ignore-working-copy --no-graph --color always  -T '
              separate(" ",
                if(description.first_line() == "",
                  "(no message)",
                  if(
                     description.first_line().substr(0, 24).starts_with(description.first_line()),
                     description.first_line().substr(0, 24),
                     description.first_line().substr(0, 23) ++ "…"
                  )
                ),
                if(conflict, "conflict"),
                if(divergent, "divergent"),
                if(hidden, "hidden"),
                bookmarks.map(|x| if(
                    x.name().substr(0, 10).starts_with(x.name()),
                    x.name().substr(0, 10),
                    x.name().substr(0, 9) ++ "…")
                  ).join(" "),
                tags.map(|x| if(
                    x.name().substr(0, 10).starts_with(x.name()),
                    x.name().substr(0, 10),
                    x.name().substr(0, 9) ++ "…")
                  ).join(" "),
              )
            '
          '';
          when = "jj root";
          symbol = "  ";
        };
      };
    };
  };
}
