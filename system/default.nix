{
  config,
  flavor,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dusk.system) hostname;
  inherit (lib) mkForce;
in
{
  imports = [
    ../user.nix

    ./ai
    ./options.nix
    ./security.nix
    ./starship.nix
    ./terminal.nix
    ./wallpapers.nix
    ./zellij.nix
  ];

  config = {
    assertions = [
      {
        assertion = flavor == "nixos" || flavor == "darwin";
        message = "System flavor must be either 'nixos' or 'darwin'";
      }
    ];

    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    environment = {
      etc = {
        "nix/inputs/nix-darwin" = mkForce { source = inputs.nix-darwin; };
        "nix/inputs/nixpkgs" = mkForce { source = inputs.nixpkgs; };
      };

      systemPackages = with pkgs; [
        bat
        btop
        cachix
        complete-alias
        curl
        direnv
        dusk-stdlib
        eva
        fastfetch
        fd
        fdupes
        ffmpeg
        file
        gh
        gist
        gitMinimal
        hyperfine
        imagemagick
        jq
        jujutsu
        lsd
        lsof
        ncdu
        nerd-fonts.inconsolata
        nss
        openssl
        p7zip
        posting
        python3
        ripgrep
        rsync
        scc
        starship
        tree
        unixtools.watch
        unzip
        watchexec
        websocat
        wget
        yazi
        zoxide
      ];

      variables.EDITOR = "nvim";
    };

    fonts = {
      packages = with pkgs; [
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
      ];
    }
    // lib.optionalAttrs (flavor == "nixos") { fontconfig.enable = true; };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      backupFileExtension = "dusk-backup";

      extraSpecialArgs = { inherit flavor inputs; };

      users.${config.dusk.username} = _: {
        imports = [
          ./options.nix
          ../user.nix
          ./home.nix
        ];
      };
    };

    networking.hostName = hostname;

    nix = {
      gc.automatic = true;
      optimise.automatic = true;

      nixPath = mkForce [ "/etc/nix/inputs" ];

      registry = {
        nixpkgs = mkForce { flake = inputs.nixpkgs; };
        nix-darwin = mkForce { flake = inputs.nix-darwin; };
      };

      settings = {
        accept-flake-config = true;
        allow-import-from-derivation = true;

        trusted-users = [
          "@wheel"
          "root"
          config.dusk.username
        ];

        experimental-features = [
          "nix-command"
          "flakes"
          # Gates `impure-env` below.
          "configurable-impure-env"
        ];

        # Expose `NIX_CURL_FLAGS` to every fetchurl builder, regardless of
        # whether the build is run by the daemon (user invocations) or
        # directly by root (`sudo nixos-rebuild switch`). crates.io's
        # CloudFront 403s any User-Agent starting with `curl/`, which is
        # exactly what nixpkgs' fetchurl hard-codes; the `--user-agent=`
        # override here rides on impureEnvVars to pass through. This also
        # reaches flake-input package builds (e.g. bun2nix's vendored
        # crates), which overlays can't.
        impure-env = [
          "NIX_CURL_FLAGS=--user-agent=Nixpkgs-fetchurl"
        ];

        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      };
    };

    programs.gnupg.agent.enable = true;
  };
}
