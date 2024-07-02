{ lib, pkgs, ... }:
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
    homebrew = {
      casks = [ "maccy" ];
    };

    system.defaults.CustomUserPreferences."org.p0deje.Maccy" = {
      SUAutomaticallyUpdate = 1;
      SUEnableAutomaticChecks = 1;
      SUHasLaunchedBefore = 1;
      searchMode = "fuzzy";
      previewDelay = 300;
      maxMenuItemLength = 75;
      menuIcon = "clipboard";
    };
  };

  linuxConfig = { };

  config = globalConfig // optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.work.clipboard = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable a clipboard manager.";
    };
  };

  config = mkIf config.protoss.work.clipboard.enable config;
}
