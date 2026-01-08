{ config, ... }:
let
  extensions = [
    "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
    "cnjifjpddelmedmihgijeibhnjfabmlf" # Obsidian Web Clipper
    "jldhpllghnbhlbpcmnajkpdmadaolakh" # Todoist for Chrome
    "khncfooichmfjbepaaaebmommgaepoid" # Unhook (make YouTube tolerable)
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
  ];
in
{
  home-manager.users.${config.dusk.username} = _: {
    programs = {
      brave = {
        enable = true;
        inherit extensions;
      };

      chromium = {
        enable = true;
        inherit extensions;
      };
    };

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "text/html" = "chromium-browser.desktop";
        "x-scheme-handler/http" = "chromium-browser.desktop";
        "x-scheme-handler/https" = "chromium-browser.desktop";
      };
    };
  };
}
