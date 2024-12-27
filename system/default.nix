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
    ./options.nix
    ./monitors.nix
    ./wallpapers.nix
    ./shell
    ../user.nix
    ./terminal
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
        age
        aider-chat
        bat
        beancount
        beets
        btop
        cachix
        complete-alias
        curl
        direnv
        duf
        dusk-ai-tools
        dusk-stdlib
        dusk-treefmt
        dust
        eva
        fava
        fd
        fdupes
        ffmpeg
        file
        gist
        gitMinimal
        hyperfine
        imagemagick
        jq
        jujutsu
        lsd
        lsof
        mkcert
        ncdu
        neofetch
        nerd-fonts.inconsolata
        nss
        openssl
        p7zip
        python3
        python3Packages.yt-dlp
        ripgrep
        rsync
        scc
        shntool
        starship
        streamlink
        tree
        unixtools.watch
        unzip
        watchexec
        wavpack
        wget
        zoxide
      ];
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      backupFileExtension = "dusk-backup";

      extraSpecialArgs = { inherit flavor inputs; };

      users.${config.dusk.username} = _: {
        imports = [
          ./options.nix
          ../user.nix
          ./home
        ];
      };
    };

    networking.hostName = hostname;

    nix = {
      package = pkgs.nix;

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

        extra-substituters = [ "https://cfcosta-home.cachix.org/" ];
        extra-trusted-public-keys = [
          "cfcosta-home.cachix.org-1:Ly4J9QkKf/WGbnap33TG0o5mG5Sa/rcKQczLbH6G66I="
        ];

        trusted-users = [
          "@wheel"
          "root"
          config.dusk.username
        ];

        experimental-features = [
          "nix-command"
          "flakes"
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
