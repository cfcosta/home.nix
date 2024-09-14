{
  config,
  pkgs,
  lib,
  inputs,
  flavor,
  ...
}:
let
  inherit (config.dusk.system) hostname;
  inherit (lib) mkForce optionals;

  darwinModules = optionals (flavor == "darwin") [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.default

    ./darwin
  ];

  linuxModules = optionals (flavor == "nixos") [
    inputs.agenix.nixosModules.default
    inputs.catppuccin.nixosModules.catppuccin
    inputs.home-manager.nixosModules.default
    inputs.nixos-cosmic.nixosModules.default

    ./nixos
  ];
in
{
  imports = darwinModules ++ linuxModules;

  config = {
    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    environment = {
      etc = {
        "nix/inputs/nixpkgs".source = inputs.nixpkgs;
        "nix/inputs/nix-darwin".source = inputs.nix-darwin;
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
        glow
        imagemagick
        inconsolata
        lsof
        ncdu_2
        neofetch
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
      users.${config.dusk.username} = ./home;

      extraSpecialArgs = {
        inherit flavor inputs;
      };
    };

    networking.hostName = hostname;

    nix = {
      gc.automatic = true;
      optimise.automatic = true;

      nixPath = mkForce [ "/etc/nix/inputs" ];

      registry = {
        nixpkgs.flake = inputs.nixpkgs;
        nix-darwin.flake = inputs.nix-darwin;
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

        extra-substituters = [
          "https://cache.iog.io"
          "https://hydra-node.cachix.org"
          "https://cardano-scaling.cachix.org"
        ];

        extra-trusted-public-keys = [
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
          "hydra-node.cachix.org-1:vK4mOEQDQKl9FTbq76NjOuNaRD4pZLxi1yri31HHmIw="
          "cardano-scaling.cachix.org-1:RKvHKhGs/b6CBDqzKbDk0Rv6sod2kPSXLwPzcUQg9lY="
        ];

        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];

        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        ];

        substituters = [
          "https://cache.nixos.org/"
          "https://cache.iog.io/"
        ];
      };
    };

    programs.gnupg.agent.enable = true;
  };
}
