{ config, pkgs, ... }:
let
  extensions = [
    "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
    "cnjifjpddelmedmihgijeibhnjfabmlf" # Obsidian Web Clipper
    "jldhpllghnbhlbpcmnajkpdmadaolakh" # Todoist for Chrome
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
  ];
in
{
  home-manager.users.${config.dusk.username} = _: {
    programs = {
      brave = {
        enable = true;
        package = pkgs.brave;

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
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
      };
    };
  };
}
