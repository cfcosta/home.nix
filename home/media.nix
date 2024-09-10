{
  pkgs,
  ...
}:
{
  config = {
    home.packages = with pkgs; [
      ffmpeg
      python312Packages.yt-dlp
      streamlink
    ];

  };
}
