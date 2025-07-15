{ pkgs, ... }:
let
  inherit (builtins) readFile;
in
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 32;
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "bluetooth"
          "network"
          "pulseaudio"
          "cpu"
          "battery"
          "custom/notifications"
          "custom/power-menu"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          format-icons = {
            default = "";
            "1" = "1";
            "2" = "2";
            "3" = "3";
            "4" = "4";
            "5" = "5";
            "6" = "6";
            "7" = "7";
            "8" = "8";
            "9" = "9";
            active = "󱓻";
          };
          persistent-workspaces = {
            "1" = [ ];
            "2" = [ ];
            "3" = [ ];
            "4" = [ ];
            "5" = [ ];
            "6" = [ ];
            "7" = [ ];
            "8" = [ ];
            "9" = [ ];
          };
        };

        "cpu" = {
          interval = 5;
          format = "󰍛";
          on-click = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.btop}/bin/btop";
        };

        "clock" = {
          format = "{:%A %H:%M}";
          format-alt = "{:%d %B W%V %Y}";
          tooltip = false;
        };

        "network" = {
          format-icons = [
            "󰤯"
            "󰤟"
            "󰤢"
            "󰤥"
            "󰤨"
          ];
          format = "{icon}";
          format-wifi = "{icon}";
          format-ethernet = "󰀂";
          format-disconnected = "󰖪";
          tooltip-format-wifi = "{essid} ({frequency} GHz)\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-ethernet = "⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
          tooltip-format-disconnected = "Disconnected";
          interval = 3;
          nospacing = 1;
          on-click = "${pkgs.ghostty}/bin/ghostty -e ${pkgs.networkmanager}/bin/nmtui";
        };

        "battery" = {
          format = "{capacity}% {icon}";
          format-discharging = "{icon}";
          format-charging = "{icon}";
          format-plugged = "";
          format-icons = {
            charging = [
              "󰢜"
              "󰂆"
              "󰂇"
              "󰂈"
              "󰢝"
              "󰂉"
              "󰢞"
              "󰂊"
              "󰂋"
              "󰂅"
            ];
            default = [
              "󰁺"
              "󰁻"
              "󰁼"
              "󰁽"
              "󰁾"
              "󰁿"
              "󰂀"
              "󰂁"
              "󰂂"
              "󰁹"
            ];
          };
          format-full = "Charged ";
          tooltip-format-discharging = "{power:>1.0f}W↓ {capacity}%";
          tooltip-format-charging = "{power:>1.0f}W↑ {capacity}%";
          interval = 5;
          states = {
            warning = 20;
            critical = 10;
          };
        };

        "bluetooth" = {
          format = "";
          format-disabled = "󰂲";
          format-connected = "";
          tooltip-format = "Devices connected: {num_connections}";
          on-click = "GTK_THEME=Adwaita-dark ${pkgs.blueberry}/bin/blueberry";
        };

        "pulseaudio" = {
          format = "";
          format-muted = "󰝟";
          scroll-step = 5;
          on-click = "GTK_THEME=Adwaita-dark ${pkgs.pavucontrol}/bin/pavucontrol";
          tooltip-format = "Playing at {volume}%";
          on-click-right = "${pkgs.helvum}/bin/helfum -t";
          ignored-sinks = [ "Easy Effects Sink" ];
        };

        "custom/notifications" = {
          format = "󰍜 ";
          on-click = "${pkgs.swaynotificationcenter}/bin/swaync-client -t";
          tooltip = false;
        };

        "custom/power-menu" = {
          format = "󰐥";
          on-click = "${pkgs.wlogout}/bin/wlogout";
          tooltip = false;
        };
      };
    };

    style = readFile ./style.css;
  };

  wayland.windowManager.hyprland.settings.exec-once = [ "${pkgs.waybar}/bin/waybar" ];
}
