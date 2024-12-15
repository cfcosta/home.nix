{ pkgs, ... }:
{
  services.dunst = {
    enable = true;

    settings = {
      global = {
        origin = "top-left";
        offset = "60x12";
        separator_height = 2;
        padding = 12;
        horizontal_padding = 12;
        text_icon_padding = 12;
        frame_width = 4;
        separator_color = "frame";
        idle_threshold = 120;
        font = "Inconsolata Nerd Font";
        line_height = 0;
        format = "<b>%s</b>\n%b";
        alignment = "center";
        icon_position = "off";
        startup_notification = "false";
        corner_radius = 12;
        frame_color = "#89b4fa";
        timeout = 2;
      };

      urgency_low = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
      };

      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
      };

      urgency_critical = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        frame_color = "#fab387";
      };
    };
  };

  wayland.windowManager.hyprland.settings.exec-once = [ "${pkgs.dunst}/bin/dunst" ];
}
