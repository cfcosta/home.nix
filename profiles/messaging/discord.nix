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
    homebrew.casks = [ "discord" ];
  };

  linuxConfig = {
    environment.systemPackages = with pkgs; [ discord ];
  };

  cfg = optionalAttrs isDarwin darwinConfig // optionalAttrs isLinux linuxConfig;
in
{
  options.protoss.messaging.discord = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable the Discord Messenger";
    };
  };

  config = mkIf config.protoss.messaging.discord.enable cfg;
}
