{ inputs, ... }:
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
    nix.useDaemon = true;
    services.nix-daemon.enable = true;
  };
}
