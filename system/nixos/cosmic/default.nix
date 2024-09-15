{
  config,
  lib,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.dusk.system.nixos.desktop;
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };
    };

    home-manager.users.${config.dusk.username}.xdg.configFile = {
      "cosmic/com.system76.CosmicComp/v1/autotile".text = "true";
      "cosmic/com.system76.CosmicComp/v1/autotile_behavior".text = "true";
      "cosmic/com.system76.CosmicComp/v1/cursor_follows_focus".text = "true";
      "cosmic/com.system76.CosmicComp/v1/focus_follows_cursor".text = "true";
      "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/gaps".text = "(8, 24)";
      "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/palette".source = "${inputs.catppuccin-cosmic}/cosmic-settings/Catppuccin-Mocha-Blue.ron";
      "cosmic/com.system76.CosmicTheme.Dark/v1/gaps".text = "(8, 24)";
      "cosmic/com.system76.CosmicTheme.Dark/v1/palette".source = "${inputs.catppuccin-cosmic}/cosmic-settings/Catppuccin-Mocha-Blue.ron";
      "cosmic/com.system76.CosmicTk/v1/apply_theme_global".text = "true";
      "cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".source = ./cosmic/shortcuts.ron;
    };

    services = {
      desktopManager.cosmic.enable = true;
      flatpak.enable = true;
      libinput.enable = true;
      packagekit.enable = true;

      xserver = {
        enable = true;

        displayManager.gdm = {
          enable = true;
          autoSuspend = false;
          wayland = true;
        };
      };
    };
  };
}
