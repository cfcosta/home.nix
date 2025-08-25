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

    ./options.nix
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
        gist
        gitMinimal
        glimpse
        hyperfine
        imagemagick
        jq
        jujutsu
        lsd
        lsof
        ncdu
        nerd-fonts.inconsolata
        nss
        opencode
        openssl
        p7zip
        posting
        python3
        python3Packages.yt-dlp
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
        zoxide
      ];

      variables.EDITOR = "nvim";
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
