{
  config,
  pkgs,
  ...
}:
{
  home-manager.users.${config.dusk.username} = _: {
    programs.brave = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
        "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
      ];
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
