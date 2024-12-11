{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    environment.sessionVariables = {
      BROWSER = config.dusk.defaults.browser;
      TERMINAL = config.dusk.defaults.terminal;
      QT_QPA_PLATFORM = "wayland";
    };

    home-manager.users.${config.dusk.username} = {
    };

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    services.xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };
}
