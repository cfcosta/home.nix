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
    homebrew.casks = [ "brave-browser" ];
  };

  linuxConfig = {
    environment.systemPackages = [ pkgs.brave ];
  };

  config = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.internet.brave-browser = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the Brave Browser";
    };
  };

  config = mkIf config.protoss.internet.brave-browser.enable config;
}
