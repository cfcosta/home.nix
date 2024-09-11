{
  hostname,
  inputs,
  flavor,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals mkForce;
in
{
  imports =
    [
      ./options.nix
      ./defaults
      ./machines/${hostname}
    ]
    ++ optionals (flavor == "darwin") [
      inputs.agenix.darwinModules.default
      inputs.home-manager.darwinModules.home-manager

      ./darwin
    ]
    ++ optionals (flavor == "nixos") [
      inputs.agenix.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
      inputs.nixos-cosmic.nixosModules.default

      ./nixos
    ];

  config = {
    environment.etc = {
      "nix/inputs/nixpkgs".source = inputs.nixpkgs;
    } // mkIf (flavor == "darwin") { "nix/inputs/nix-darwin".source = inputs.nix-darwin; };

    nix = {
      nixPath = mkForce [ "/etc/nix/inputs" ];

      registry.nixpkgs.flake = inputs.nixpkgs;
    } // mkIf (flavor == "darwin") { registry.nix-darwin.flake = inputs.nix-darwin; };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.dusk.username} =
        { ... }:
        {
          imports = [
            inputs.agenix.homeManagerModules.default
            inputs.neovim.hmModule

            ./options.nix
            ./machines/${hostname}/dusk.nix
            ./home
          ];

          home.stateVersion = "24.11";

          programs.alacritty.settings.import = [
            pkgs.alacritty-theme."${config.dusk.theme.settings.alacritty}"
          ];
        };
    };
  };
}
