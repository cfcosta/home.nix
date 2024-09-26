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
    nix = {
      useDaemon = true;

      # Enable building Linux packages using a VM
      linux-builder.enable = true;
      settings.trusted-users = [ "@admin" ];
    };

    environment.systemPackages = with pkgs; [
      feishin
    ];

    services.nix-daemon.enable = true;
  };
}
