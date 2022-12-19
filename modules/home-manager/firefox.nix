{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.devos.home.firefox;
  themeConfig = {
    profile = {
      settings = {
        # For Firefox GNOME theme:
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.uidensity" = 0;
        "svg.context-properties.content.enabled" = true;
      };
      userChrome = ''
        @import "firefox-gnome-theme/userChrome.css";
      '';
      userContent = ''
        @import "firefox-gnome-theme/userContent.css";
      '';
    };
  };
in {
  options = {
    devos.home.firefox = {
      enable = mkEnableOption "firefox";
      gnomeTheme = mkEnableOption "firefox";
    };
  };

  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;

      profiles.default = mkMerge [
        { name = "Default"; }
        (mkIf cfg.gnomeTheme themeConfig.profile)
      ];
    };

    home.file."firefox-gnome-theme" = mkIf cfg.gnomeTheme {
      target = ".mozilla/firefox/default/chrome/firefox-gnome-theme";
      source = pkgs.fetchFromGitHub {
        owner = "rafaelmardojai";
        repo = "firefox-gnome-theme";
        rev = "v105";
        sha256 = "sha256-CXRKJ+xsv+/jN5DIpLFGvMH0XgVMbJjn1DkFIsZ4d4k=";
      };
    };
  };
}
