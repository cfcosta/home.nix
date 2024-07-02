{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    mkIf
    optionalAttrs
    ;
  inherit (pkgs.stdenv) isLinux isDarwin;

  darwinConfig = {
    homebrew.casks = [ "tailscale" ];
  };

  linuxConfig = {
    services.tailscale.enable = true;

    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  cfg = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.internet.tailscale = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable Docker for running containers.";
    };
  };

  config = mkIf config.protoss.internet.tailscale.enable cfg;
}
