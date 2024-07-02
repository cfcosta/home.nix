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
    homebrew.casks = [ "firefox" ];
  };

  linuxConfig = {
    programs.firefox.enable = true;
  };

  cfg = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.internet.firefox = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the Firefox Browser";
    };
  };

  config = mkIf config.protoss.internet.firefox.enable cfg;
}
