{ pkgs, ... }:
{
  services.mako = {
    enable = true;

    settings = {
      borderRadius = 16;
      borderSize = 1;
      margin = "18";
      maxIconSize = 52;
      padding = "12";
    };
  };

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod, escape, exec, ${pkgs.mako}/bin/makoctl dismiss"
    ];

    exec-once = [ "${pkgs.mako}/bin/mako" ];
  };
}
