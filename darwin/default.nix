{ ... }:
{
  imports = [
    ./clipboard.nix
    ./homebrew.nix
    ./raycast.nix
    ./system.nix
  ];

  config = {
    age.secrets = {
      "env.sh.age".file = ../secrets/env.sh.age;
      "nix.conf.age".file = ../secrets/nix.conf.age;
    };

    nix.useDaemon = true;
    services.nix-daemon.enable = true;
  };
}
