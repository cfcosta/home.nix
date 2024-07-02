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

  darwinConfig = {
    homebrew.casks = [ "element" ];
  };

  linuxConfig = {
    environment.systemPackages = with pkgs; [
      element-desktop
      fractal
    ];
  };

  cfg = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.messaging.matrix = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the Element (or Fractal) for Matrix Messaging";
    };
  };

  config = mkIf config.protoss.messaging.matrix.enable cfg;
}
