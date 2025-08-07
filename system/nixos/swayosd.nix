{ config, pkgs, ... }:
let
  client = "${pkgs.swayosd}/bin/swayosd-client";
in
{
  home-manager.users.${config.dusk.username} = {
    services.swayosd.enable = true;

    wayland.windowManager.hyprland.settings = {
      bind = [
        ", XF86AudioRaiseVolume, exec, ${client} --output-volume raise"
        ", XF86AudioLowerVolume, exec , ${client} --output-volume lower"
        ", XF86AudioMute, exec, ${client} --output-volume mute-toggle"
        ", XF86AudioMicMute, exec, ${client} --input-volume mute-toggle"
        ", XF86AudioRaiseVolume, exec, ${client} --output-volume raise --max-volume 100"
        ", XF86AudioLowerVolume, exec, ${client} --output-volume lower --max-volume 100"
        ", XF86MonBrightnessUp, exec, ${client} --brightness raise"
        ", XF86MonBrightnessDown, exec, ${client} --brightness lower"
      ];

      bindr = [ "CAPS, Caps_Lock, exec, ${client} --caps-lock" ];
    };

    xdg = {
      enable = true;

      configFile."swayosd/style.css".text = ''
        @define-color background-color #24273a;
        @define-color border-color #c6d0f5;
        @define-color label #cad3f5;
        @define-color image #cad3f5;
        @define-color progress #cad3f5;

        window {
          border-radius: 0;
          opacity: 0.97;
          border: 2px solid @border-color;

          background-color: @background-color;
        }

        label {
          font-family: 'Inconsolata NerdFont', monospace;
          font-size: 11pt;

          color: @label;
        }

        image {
          color: @image;
        }

        progressbar {
          border-radius: 0;
        }

        progress {
          background-color: @progress;
        }
      '';
    };
  };
}
