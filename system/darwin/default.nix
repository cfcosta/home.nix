_: {
  imports = [
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
