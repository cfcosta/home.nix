inputs:
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkForce
    optionals
    ;
  inherit (inputs)
    agenix
    home-manager
    neovim
    nixos-cosmic
    nixpkgs
    nix-darwin
    ;
  inherit (config.dusk.system) hostname flavor;

  mod = if flavor == "darwin" then "darwinModules" else "nixosModules";
in
{
  imports =
    [
      agenix.${mod}.default
      home-manager.${mod}.home-manager

      ./defaults
      ./options.nix
      ./user.nix
      ./machines/${hostname}.nix
    ]
    ++ optionals (flavor == "darwin") [ ./darwin ]
    ++ optionals (flavor == "nixos") [
      nixos-cosmic.nixosModules.default
      ./nixos
    ];

  config = {
    environment.etc = {
      "nix/inputs/nixpkgs".source = nixpkgs;
      "nix/inputs/nix-darwin".source = nix-darwin;
    };

    networking.hostName = hostname;

    nix = {
      nixPath = mkForce [ "/etc/nix/inputs" ];

      registry = {
        nixpkgs.flake = nixpkgs;
        nix-darwin.flake = nix-darwin;
      };
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.dusk.username} =
        { ... }:
        {
          imports = [
            agenix.homeManagerModules.default
            neovim.hmModule

            ./options.nix
            ./user.nix
            ./machines/${hostname}/dusk.nix

            ./home
          ];

          home.stateVersion = "24.11";

        };
    };
  };
}
