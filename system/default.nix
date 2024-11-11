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
    ../user.nix
  ];

  config = {
    assertions = [
      {
        assertion = flavor == "nixos" || flavor == "darwin";
        message = "System flavor must be either 'nixos' or 'darwin'";
      }
    ];

    age.secrets.rootCA-key = {
      file = ../secrets/rootCA-key.pem.age;
      path = "/etc/mkcert/rootCA-key.pem";

      owner = config.dusk.username;
      mode = "600";
    };

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
        "mkcert/rootCA.pem".source = ../secrets/rootCA.pem;
      };

      systemPackages = with pkgs; [
        (nerdfonts.override { fonts = [ "Inconsolata" ]; })

        age
        aider-chat
        b3sum
        bat
        beancount
        btop
        cachix
        cmatrix
        complete-alias
        curl
        direnv
        duf
        dust
        eternal-terminal
        eva
        fava
        fd
        fdupes
        ffmpeg
        figlet
        file
        gh
        gh-dash
        gist
        git-bug
        gitMinimal
        gitui
        glow
        imagemagick
        inconsolata
        jq
        jujutsu
        lsd
        lsof
        mkcert
        neofetch
        nss
        openssl
        p7zip
        pricehist
        python3
        python3Packages.yt-dlp
        ripgrep
        rsync
        scc
        starship
        streamlink
        tmux
        tmuxp
        tree
        unixtools.watch
        unzip
        watchexec
        wget
        zoxide
      ];
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      backupFileExtension = "dusk-backup";

      extraSpecialArgs = {
        inherit flavor inputs;
      };

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

    security.pki.certificateFiles = [ ../secrets/rootCA.pem ];

    system.activationScripts.install-self-signed-certs = {
      text = ''
        CAROOT=/etc/mkcert ${pkgs.mkcert}/bin/mkcert -install
      '';
    };
  };
}
