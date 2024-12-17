{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (builtins) concatLists genList toString;

  cfg = config.dusk.system.nixos.desktop.hyprland;

  keybindings = {
    # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
    switch-workspace = concatLists (
      genList (
        i:
        let
          ws = i + 1;
        in
        [
          "$mod, code:1${toString i}, workspace, ${toString ws}"
          "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]
      ) 9
    );

    window-movement = [
      "$mod, h, movefocus, l"
      "$mod, j, movefocus, d"
      "$mod, k, movefocus, u"
      "$mod, l, movefocus, r"

      "$mod SHIFT, h, movewindow, l"
      "$mod SHIFT, j, movewindow, d"
      "$mod SHIFT, k, movewindow, u"
      "$mod SHIFT, l, movewindow, r"
    ];

    window-management = [
      "$mod, Q, killactive"
      "$mod, F, fullscreen"
    ];
  };
in
{
  imports = [ ./sunshine.nix ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };

      systemPackages = with pkgs; [
        dunst
        grimblast
        rofi
      ];
    };

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    security.pam.services.hyprlock = { };

    services.xserver.displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      config = {
        common.default = [ "gtk" ];
        hyprland.default = [
          "gtk"
          "hyprland"
        ];
      };

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-wlr
      ];
    };

    home-manager.users.${config.dusk.username} = {
      imports = [
        ./dunst
        ./waybar
      ];

      gtk.enable = true;

      home.pointerCursor = {
        name = "Adwaita";
        package = pkgs.adwaita-icon-theme;
        size = 24;
        x11 = {
          enable = true;
          defaultCursor = "Adwaita";
        };
      };

      programs = {
        hyprlock.enable = true;
        rofi = {
          enable = true;
          package = pkgs.rofi-wayland;
        };
        wlogout.enable = true;
      };

      services = {
        clipman.enable = true;
        hypridle.enable = true;
        hyprpaper = {
          enable = true;
          settings = {
            ipc = "on";
            splash = false;
          };
        };
      };

      wayland.windowManager.hyprland = {
        enable = true;

        settings = {
          "$mod" = "SUPER";

          general = {
            gaps_in = 8;
            gaps_out = 24;
            border_size = 3;
          };

          decoration = {
            inactive_opacity = 0.90;
            fullscreen_opacity = 1.0;
            rounding = 4;

            blur = {
              enabled = true;
              size = 8;
              passes = 2;
            };
          };

          animations = {
            enabled = true;
            bezier = "overshot, 0.05, 0.9, 0.1, 1.1";
            animation = [
              "windows, 1, 1.5, overshot"
              "windowsOut, 1, 1.5, overshot, popin 80%"
              "border, 1, 10, overshot"
              "fade, 1, 7, overshot"
              "workspaces, 1, 1.5, overshot"
            ];
          };

          bind =
            [
              ''$mod SHIFT, V, exec, bash -c "${pkgs.clipman}/bin/clipman pick -t rofi --err-on-no-selection && ${pkgs.wtype}/bin/wtype -M ctrl -M shift v"''
              "$mod SHIFT, escape, exec, ${pkgs.wlogout}/bin/wlogout"

              # Application launchers
              ''$mod, Space, exec, ${pkgs.rofi-wayland}/bin/rofi -show-icons -show drun''
              ''$mod SHIFT, Space, exec, ${pkgs.rofi-wayland}/bin/rofi -show run''

              "$mod, Return, exec, ${config.dusk.defaults.terminal}"
              "$mod, B, exec, ${config.dusk.defaults.browser}"
              ", Print, exec, ${pkgs.grimblast}/bin/grimblast copy area"
            ]
            ++ keybindings.window-movement
            ++ keybindings.window-management
            ++ keybindings.switch-workspace;
        };

        systemd.variables = [ "--all" ];
      };
    };
  };
}
