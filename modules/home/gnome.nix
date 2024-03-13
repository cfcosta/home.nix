{ config, lib, pkgs, ... }:
with lib;
let
  inherit (lib.hm.gvariant) mkTuple;
  cfg = config.dusk.home;

  match = v: l:
    builtins.elemAt
    (lib.lists.findFirst (x: (if_let v (builtins.elemAt x 0)) != null) null l)
    1;

  defaultBrowser = match cfg.defaults [
    [ { browser = "firefox"; } "firefox.desktop" ]
    [ { browser = "brave"; } "brave-browser.desktop" ]
  ];
in {
  options = {
    dusk.home.gnome = {
      enable = mkEnableOption "gnome";
      darkTheme = mkEnableOption "gnome-dark-theme";

      keymaps = mkOption {
        type = types.listOf types.str;
        default = [ "us" ];
      };

      numberOfWorkspaces = mkOption {
        type = types.int;
        default = 6;
      };

      defaults.browser = mkOption {
        type = types.enum [ "firefox" "brave" ];
        default = "firefox";
      };
    };
  };

  config = mkIf cfg.gnome.enable {
    home.packages = with pkgs; [ adw-gtk3 ];

    home.sessionVariables = {
      GTK_IM_MODULE = "cedilla";
      QT_IM_MODULE = "cedilla";
    };

    qt.enable = true;
    qt.platformTheme = "gnome";
    qt.style.package = pkgs.adwaita-qt;
    qt.style.name = if cfg.gnome.darkTheme then "adwaita-dark" else "adwaita";

    home.file.".XCompose".text = ''
      include "/%L"

      <dead_acute> <c> : "ç"
      <dead_acute> <C> : "Ç"
    '';

    home.file.".config/Element/config.json".text =
      builtins.readFile ./element/config.json;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme =
          if cfg.gnome.darkTheme then "prefer-dark" else "prefer-light";
        gtk-theme = if cfg.gnome.darkTheme then "adw-gtk3-dark" else "adw-gtk3";

        clock-show-weekday = true;
      };

      "org/gnome/desktop/wm/preferences" = {
        # Disable delay on changing window focus (for mouse to focus)
        focus-mode = "sloppy";

        # Set a fixed number of workspaces
        num-workspaces = cfg.gnome.numberOfWorkspaces;
      };

      "org/gnome/mutter" = {
        # Enable mouse to focus
        focus-change-on-pointer-rest = false;

        # Enable edge tiling (drag window to screen corners to fill the space)
        edge-tiling = true;

        # Disable dynamic workspaces
        dynamic-workspaces = false;
      };

      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        move-to-workspace-1 = [ "<Shift><Super>exclam" ];
        move-to-workspace-2 = [ "<Shift><Super>at" ];
        move-to-workspace-3 = [ "<Shift><Super>numbersign" ];
        move-to-workspace-4 = [ "<Shift><Super>dollar" ];
        move-to-workspace-5 = [ "<Shift><Super>percent" ];
        move-to-workspace-6 = [ "<Shift><Super>dead_circumflex" ];
        switch-input-source = [ "<Super>Tab" ];
        switch-input-source-backward = [ "<Shift><Super>Tab" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        switch-to-workspace-5 = [ "<Super>5" ];
        switch-to-workspace-6 = [ "<Super>6" ];
        toggle-fullscreen = [ "<Super>f" ];
        switch-applications = [ ];
        switch-applications-backward = [ ];
      };

      "org/gnome/settings-daemon/plugins/media-keys" = {
        # Lock Screen
        screensaver = [ "Pause" ];

        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" =
        {
          binding = "<Super>b";
          command = "firefox";
          name = "Launch Browser";
        };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" =
        {
          binding = "<Super>Return";
          command = "alacritty";
          name = "Launch Terminal";
        };

      "org/gnome/desktop/input-sources" = {
        sources = map (x: (mkTuple [ "xkb" x ])) cfg.gnome.keymaps;
      };

      "org/gnome/shell" = {
        disable-user-extensions = false;

        enabled-extensions = [ "forge@jmmaranan.com" ];
        disabled-extensions = [ ];

        # Disable gnome tour when starting for the first time by setting a
        # really high version.
        welcome-dialog-last-shown-version = "4294967295";
      };

      "org/gnome/shell/extensions/forge" = {
        tiling-mode-enabled = true;
        window-gap-size = 4;
        window-gap-size-increment = 1;
        window-gap-hidden-on-single = true;
      };
    };

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = [ defaultBrowser ];
      "x-scheme-handler/https" = [ defaultBrowser ];
      "x-scheme-handler/chrome" = [ defaultBrowser ];
      "text/html" = [ defaultBrowser ];
      "application/x-extension-htm" = [ defaultBrowser ];
      "application/x-extension-html" = [ defaultBrowser ];
      "application/x-extension-shtml" = [ defaultBrowser ];
      "application/xhtml+xml" = [ defaultBrowser ];
      "application/x-extension-xhtml" = [ defaultBrowser ];
      "application/x-extension-xht" = [ defaultBrowser ];
    };
  };
}
