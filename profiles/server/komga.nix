{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
  inherit (pkgs.stdenv) isLinux;
in
{
  options.protoss.server.komga = {
    enable = mkOption {
      type = types.bool;
      default = isLinux;
      description = "Whether or not to enable the Komga (Manga Reader) server";
    };
  };

  config = mkIf config.protoss.server.komga.enable {
    services.komga = {
      enable = true;

      openFirewall = false;
    };
  };
}
