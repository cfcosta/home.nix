{ config, pkgs, ... }:
let
  extensions = [
    "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
    "cnjifjpddelmedmihgijeibhnjfabmlf" # Obsidian Web Clipper
    "jldhpllghnbhlbpcmnajkpdmadaolakh" # Todoist for Chrome
    "khncfooichmfjbepaaaebmommgaepoid" # Unhook (make YouTube tolerable)
    "dbepggeogbaibhgnhhndojpepiihcmeb" # Vimium
  ];

  browserMimeTypes = [
    "application/pdf"
    "application/rdf+xml"
    "application/rss+xml"
    "application/xhtml+xml"
    "application/xhtml_xml"
    "application/xml"
    "image/gif"
    "image/jpeg"
    "image/png"
    "image/webp"
    "text/html"
    "text/xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/chromium"
  ];

  mkRemoteDebugBrowser =
    {
      binary,
      package,
      port,
    }:
    pkgs.writeShellScriptBin "${binary}-remote-debug" ''
      exec ${package}/bin/${binary} \
        --remote-debugging-port=${toString port} \
        --remote-debugging-address=127.0.0.1 \
        "$@"
    '';

  chromiumRemoteDebug = mkRemoteDebugBrowser {
    binary = "chromium";
    package = pkgs.chromium;
    port = 9222;
  };

  braveRemoteDebug = mkRemoteDebugBrowser {
    binary = "brave";
    package = pkgs.brave;
    port = 9224;
  };

  mkBrowserDesktopEntry =
    {
      name,
      icon,
      exec,
      startupWMClass ? null,
    }:
    ''
      [Desktop Entry]
      Version=1.0
      Name=${name}
      Comment=Access the Internet
      Exec=${exec} %U
      ${if startupWMClass == null then "" else "StartupWMClass=${startupWMClass}\n"}StartupNotify=true
      Terminal=false
      Icon=${icon}
      Type=Application
      Categories=Network;WebBrowser;
      MimeType=${builtins.concatStringsSep ";" browserMimeTypes};
      Actions=new-window;new-private-window;

      [Desktop Action new-window]
      Name=New Window
      Exec=${exec}

      [Desktop Action new-private-window]
      Name=New Incognito Window
      Exec=${exec} --incognito
    '';
in
{
  config = {
    dusk.defaults.browser = "${chromiumRemoteDebug}/bin/chromium-remote-debug";

    home-manager.users.${config.dusk.username} = _: {
      home = {
        packages = [
          chromiumRemoteDebug
          braveRemoteDebug
        ];

        file = {
          ".local/share/applications/chromium-browser.desktop".text = mkBrowserDesktopEntry {
            name = "Chromium";
            icon = "chromium";
            exec = "${chromiumRemoteDebug}/bin/chromium-remote-debug";
            startupWMClass = "chromium-browser";
          };

          ".local/share/applications/brave-browser.desktop".text = mkBrowserDesktopEntry {
            name = "Brave Web Browser";
            icon = "brave-browser";
            exec = "${braveRemoteDebug}/bin/brave-remote-debug";
          };
        };
      };

      programs = {
        bash.shellAliases = {
          brave = "brave-remote-debug";
          chromium = "chromium-remote-debug";
        };

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
  };
}
