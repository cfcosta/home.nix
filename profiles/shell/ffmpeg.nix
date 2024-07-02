{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
in
{
  options.protoss.protoss.shell.ffmpeg = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable ffmpeg and related applications";
    };
  };

  config = mkIf config.protoss.shell.ffmpeg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg-full
      python312Packages.yt-dlp
    ];
  };
}
