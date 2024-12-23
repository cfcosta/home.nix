args@{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;
in
{
  options.dusk.folders.media = {
    root = mkOption {
      type = types.str;
      default = "${config.dusk.folders.downloads}/Media";
      description = "The root folder for downloaded media, like books, movies, TV shows.";
    };

    data = mkOption {
      type = types.str;
      default = "${config.dusk.folders.media.root}/_data";
      description = "The folder where download aplications will keep their data (for easy back-up).";
    };
  };

  imports = [
    inputs.agenix.nixosModules.default

    (import ./deluge.nix args)
    (import ./gitea.nix args)
    (import ./jellyfin.nix args)
    (import ./lidarr.nix args)
    (import ./navidrome.nix args)
    (import ./prowlarr.nix args)
    (import ./readarr.nix args)
    (import ./traefik.nix args)
  ];
}
