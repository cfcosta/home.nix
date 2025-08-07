{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib) mkOption types;

  launchFloating =
    cmd: ''${pkgs.ghostty}/bin/ghostty --class=com.mitchellh.ghostty.floating -e ${cmd}'';
in
{
  options.dusk.waybar = {
    font-family = mkOption {
      type = types.str;
      default = "Inconsolata NerdFont";
    };

    font-size = mkOption {
      type = types.int;
      default = 14;
    };

    font-weight = mkOption {
      type = types.str;
      default = "bold";
    };
  };

  config.home-manager.users.${config.dusk.username} = {
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
          };

          "cpu" = {
            interval = 5;
            format = "󰍛";
            on-click = launchFloating "${pkgs.btop}/bin/btop";
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
            on-click = launchFloating "${pkgs.nm-wifi}/bin/nm-wifi";
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
            format-connected = "󰂯";
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

      style = ''
        @define-color rosewater #f5e0dc;
        @define-color flamingo #f2cdcd;
        @define-color pink #f5c2e7;
        @define-color mauve #cba6f7;
        @define-color red #f38ba8;
        @define-color maroon #eba0ac;
        @define-color peach #fab387;
        @define-color yellow #f9e2af;
        @define-color green #a6e3a1;
        @define-color teal #94e2d5;
        @define-color sky #89dceb;
        @define-color sapphire #74c7ec;
        @define-color blue #89b4fa;
        @define-color lavender #b4befe;
        @define-color text #cdd6f4;
        @define-color subtext1 #bac2de;
        @define-color subtext0 #a6adc8;
        @define-color overlay2 #9399b2;
        @define-color overlay1 #7f849c;
        @define-color overlay0 #6c7086;
        @define-color surface2 #585b70;
        @define-color surface1 #45475a;
        @define-color surface0 #313244;
        @define-color base #1e1e2e;
        @define-color mantle #181825;
        @define-color crust #11111b;

        * {
          border-radius: 0;
          border: none;
          color: @text;
          font-family: ${config.dusk.waybar.font-family};
          font-size: ${toString config.dusk.waybar.font-size}px;
          font-weight: ${config.dusk.waybar.font-weight};
          min-height: 0;
        }

        window#waybar {
          background-color: shade(@base, 0.9);
          border: 2px solid alpha(@crust, 0.3);
        }

        #workspaces {
          margin-left: 7px;
        }

        #workspaces button {
          all: initial;
          padding: 2px 6px;
          margin-right: 3px;
        }

        #custom-dropbox,
        #cpu,
        #battery,
        #network,
        #bluetooth,
        #pulseaudio,
        #clock,
        #custom-power-menu {
          min-width: 12px;
          margin-right: 13px;
        }

        tooltip {
          padding: 2px;
        }

        tooltip label {
          padding: 2px;
        }
      '';
    };

    wayland.windowManager.hyprland.settings.exec-once = [ "${pkgs.waybar}/bin/waybar" ];
  };
}
