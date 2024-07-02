{ lib, pkgs, ... }:
let
  inherit (lib)
    mkOption
    types
    mkIf
    optionalAttrs
    ;
  inherit (pkgs.stdenv) isLinux isDarwin;

  darwinConfig = {
    homebrew.casks = [ "bitwarden" ];
  };

  linuxConfig = {
    environment.systemPackages = [ pkgs.bitwarden ];
  };

  config = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.internet.bitwarden = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the Bitwarden Pasword Manager";
    };
  };

  config = mkIf config.protoss.internet.bitwarden.enable config;
}
