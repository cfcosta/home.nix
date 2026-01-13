{ config, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      pcmanfm
      tumbler
      xarchiver
    ];

    services.tumbler.enable = true;

    home-manager.users.${config.dusk.username} = _: {
      xdg.mimeApps.defaultApplications = {
        # Open directories with PCManFM
        "inode/directory" = "pcmanfm.desktop";

        # Open archive files with XArchiver
        "application/gzip" = "xarchiver.desktop";
        "application/java-archive" = "xarchiver.desktop";
        "application/vnd.android.package-archive" = "xarchiver.desktop";
        "application/vnd.rar" = "xarchiver.desktop";
        "application/x-7z-compressed" = "xarchiver.desktop";
        "application/x-bzip-compressed-tar" = "xarchiver.desktop";
        "application/x-bzip2" = "xarchiver.desktop";
        "application/x-compressed-tar" = "xarchiver.desktop";
        "application/x-gtar" = "xarchiver.desktop";
        "application/x-gzip" = "xarchiver.desktop";
        "application/x-lzma" = "xarchiver.desktop";
        "application/x-lzma-compressed-tar" = "xarchiver.desktop";
        "application/x-rar" = "xarchiver.desktop";
        "application/x-rar-compressed" = "xarchiver.desktop";
        "application/x-tar" = "xarchiver.desktop";
        "application/x-tgz" = "xarchiver.desktop";
        "application/x-xz" = "xarchiver.desktop";
        "application/x-xz-compressed-tar" = "xarchiver.desktop";
        "application/x-zip" = "xarchiver.desktop";
        "application/x-zip-compressed" = "xarchiver.desktop";
        "application/x-zstd" = "xarchiver.desktop";
        "application/x-zstd-compressed-tar" = "xarchiver.desktop";
        "application/zip" = "xarchiver.desktop";
        "application/zstd" = "xarchiver.desktop";
      };
    };
  };
}
