{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) concatStringsSep listToAttrs;
  inherit (lib) mkOption types;
  inherit (config.dusk.shell.starship) disabledModules;

  allModules = [
    "aws"
    "azure"
    "battery"
    "buf"
    "c"
    "character"
    "cmake"
    "cmd_duration"
    "cobol"
    "conda"
    "container"
    "crystal"
    "custom"
    "daml"
    "dart"
    "deno"
    "directory"
    "direnv"
    "docker_context"
    "dotnet"
    "elixir"
    "elm"
    "env_var"
    "erlang"
    "fennel"
    "fill"
    "fossil_branch"
    "fossil_metrics"
    "gcloud"
    "git_branch"
    "git_commit"
    "git_metrics"
    "git_state"
    "git_status"
    "gleam"
    "golang"
    "gradle"
    "guix_shell"
    "haskell"
    "haxe"
    "helm"
    "hg_branch"
    "hostname"
    "java"
    "jobs"
    "julia"
    "kotlin"
    "kubernetes"
    "line_break"
    "localip"
    "lua"
    "memory_usage"
    "meson"
    "nats"
    "nim"
    "nix_shell"
    "nodejs"
    "ocaml"
    "opa"
    "openstack"
    "os"
    "package"
    "perl"
    "php"
    "pijul_channel"
    "pulumi"
    "purescript"
    "python"
    "quarto"
    "raku"
    "red"
    "rlang"
    "ruby"
    "rust"
    "scala"
    "shell"
    "shlvl"
    "singularity"
    "solidity"
    "spack"
    "status"
    "sudo"
    "swift"
    "terraform"
    "time"
    "typst"
    "username"
    "vagrant"
    "vcsh"
    "vlang"
    "zig"
  ];

  overrides = listToAttrs (
    map (name: {
      inherit name;
      value.disabled = true;
    }) disabledModules
  );

  jj = "${pkgs.jujutsu}/bin/jj --ignore-working-copy";
in
{
  options.dusk.shell.starship.disabledModules = mkOption {
    type = types.listOf (types.enum allModules);
    default = [
      "dart"
      "fossil_branch"
      "fossil_metrics"
      "gradle"
      "guix_shell"
      "hg_branch"
      "java"
      "package"
      "pijul_channel"
      "vagrant"
    ];
  };

  config.home-manager.users.${config.dusk.username} = _: {
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
      settings = overrides // {
        format = concatStringsSep "" [
          "$sudo"
          "$jobs"
          "$battery"
          "$time"
          "$status"
          "$container"
          "$shell"
          "$os"
          "$username"
          "$hostname"
          "$localip"
          "$directory"
          "$cmd_duration"
          "$custom"
          "$nix_shell"
          "$all"
          "$line_break"
          "$character"
        ];

        aws.symbol = "  ";
        buf.symbol = " ";
        c.symbol = " ";
        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[λ](bold red)";
        };
        conda.symbol = " ";
        crystal.symbol = " ";
        dart.symbol = " ";
        directory = {
          format = "[$path]($style)[$read_only]($read_only_style) ";
          truncate_to_repo = false;
        };
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
          symbol = " ";
          only_attached = true;
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
          format = "with [$symbol $name]($style) ";
        };
        nodejs.symbol = " ";
        ocaml.symbol = " ";
        package.symbol = "󰏗 ";
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
          AlmaLinux = " ";
          Alpaquita = " ";
          Alpine = " ";
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
          OracleLinux = "󰌷 ";
          Pop = " ";
          Raspbian = " ";
          RedHatEnterprise = " ";
          Redhat = " ";
          Redox = "󰀘 ";
          RockyLinux = " ";
          SUSE = " ";
          Solus = "󰠳 ";
          Ubuntu = " ";
          Unknown = " ";
          Void = " ";
          Windows = "󰍲 ";
          openSUSE = " ";
        };

        custom.jj = {
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
            printf "$GREEN$RESET %s $GRAY($GREEN+%d $RED-%d$GRAY)$RESET" "$change_id" $stats
          '';
          when = "${jj} root";
          format = "on $output ";
        };

      };
    };
  };
}
