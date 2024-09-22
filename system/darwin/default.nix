{ inputs, pkgs, ... }:
{
  imports = [
    inputs.agenix.darwinModules.default
    inputs.home-manager.darwinModules.default

    ./clipboard.nix
    ./homebrew.nix
    ./raycast.nix
    ./system.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      feishin
    ];

    nix.useDaemon = true;
    services.nix-daemon.enable = true;
  };
}
