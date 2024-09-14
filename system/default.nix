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
    ../options.nix
    ../user.nix
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
        "nix/inputs/nixpkgs" = mkForce { source = inputs.nixpkgs; };
        "nix/inputs/nix-darwin" = mkForce { source = inputs.nix-darwin; };
      };

      systemPackages = with pkgs; [
        age
        b3sum
        complete-alias
        curl
        eva
        fd
        fdupes
        ffmpeg
        file
        gist
        git-bug
        gitMinimal
        gitui
        glow
        imagemagick
        inconsolata
        lsof
        ncdu_2
        neofetch
        openssl
        python3
        python3Packages.yt-dlp
        ripgrep
        rsync
        scc
        streamlink
        tmux
        tmuxp
        tree
        unixtools.watch
        unzip
        watchexec
        wget
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
          ../options.nix
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
        auto-optimise-store = true;

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

    security.pki.certificateFiles = [
      ./certificates/ca.crt
    ];
  };
}
