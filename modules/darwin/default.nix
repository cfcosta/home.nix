{ pkgs, ... }:
let
  inherit (pkgs.dusk.inputs) home-manager;
in
{
  imports = [
    home-manager.darwinModules.home-manager

    ../defaults

    ./clipboard.nix
    ./homebrew.nix
    ./raycast.nix
    ./system.nix
  ];

  config = {
    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    environment.etc."nix/inputs/nix-darwin".source = "${pkgs.dusk.inputs.nix-darwin}";

    environment.systemPackages = with pkgs; [
      curl
      file
      git
      wget
    ];

    programs.bash = {
      enable = true;
      package = pkgs.bashInteractive;
    };

    programs.gnupg.agent.enable = true;

    registry.nix-darwin.flake = pkgs.dusk.inputs.nix-darwin;
  };
}
