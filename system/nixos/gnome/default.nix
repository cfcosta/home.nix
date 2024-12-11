{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.gnome;
in
{
  config = mkIf cfg.enable {
    environment.sessionVariables = {
      BROWSER = config.dusk.defaults.browser;
      TERMINAL = config.dusk.defaults.terminal;
      QT_QPA_PLATFORM = "wayland";
    };

    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };
}
