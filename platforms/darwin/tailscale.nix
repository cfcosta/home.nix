{ config, pkgs, dusk, ... }: {
  config = {
    homebrew.masApps = { "Tailscale" = 1475387142; };
    networking.knownNetworkServices = [ "Tailscale Tunnel" ];
  };
}
