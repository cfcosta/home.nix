{ pkgs, ... }:
{
  services.mako = {
    enable = true;

    borderRadius = 16;
    borderSize = 1;
    margin = "18";
    maxIconSize = 52;
    padding = "12";
  };

  wayland.windowManager.hyprland.settings.exec-once = [ "${pkgs.mako}/bin/mako" ];
}
