{
  lib,
  pkgs,
  config,
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

  globalConfig = {
    environment.systemPackages = with pkgs; [
      docker-compose
      ctop
    ];
  };

  darwinConfig = {
    homebrew.casks = [ "orbstack" ];
  };

  linuxConfig = {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    users.users."${config.protoss.user.username}".extraGroups = [ "docker" ];
  };

  cfg = globalConfig // optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.server.docker = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable Docker for running containers.";
    };
  };

  config = mkIf config.protoss.server.docker.enable cfg;
}
