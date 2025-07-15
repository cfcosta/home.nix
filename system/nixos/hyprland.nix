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
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
        GTK_THEME = "dark";
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

    services = {
      gnome.gnome-keyring.enable = true;

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
        wayland = true;
      };
    };

    xdg.portal = {
      enable = true;
      xdgOpenUsePortal = true;

      config.hyprland.default = [
        "gtk"
        "hyprland"
      ];

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-wlr
      ];
    };

    home-manager.users.${config.dusk.username} = {
      dconf.enable = true;

      gtk = {
        enable = true;

        cursorTheme = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
        };

        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };

        theme = {
          name = "palenight";
          package = pkgs.palenight-theme;
        };

        gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
        gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
      };

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
        swaync.enable = true;
      };

      wayland.windowManager.hyprland = {
        enable = true;

        settings = {
          "$mod" = "SUPER";

          bind =
            [
              ''$mod SHIFT, V, exec, bash -c "${pkgs.clipman}/bin/clipman pick -t rofi --err-on-no-selection && ${pkgs.wtype}/bin/wtype -M ctrl -M shift v"''
              "$mod SHIFT, escape, exec, ${pkgs.wlogout}/bin/wlogout"

              # Application launchers
              ''$mod, Space, exec, ${pkgs.rofi-wayland}/bin/rofi -show-icons -show drun''
              ''$mod SHIFT, Space, exec, ${pkgs.rofi-wayland}/bin/rofi -show run''
              ''$mod CTRL, L, exec, ${pkgs.hyprlock}/bin/hyprlock''

              "$mod, Return, exec, ${config.dusk.terminal.default}"
              "$mod, escape, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -op"
              "$mod, B, exec, ${config.dusk.defaults.browser}"
              "$mod, M, exec, ${config.dusk.defaults.music-player}"
              "$mod, D, exec, ${pkgs.discord}/bin/discord"
              "$mod, T, exec, ${pkgs.todoist-electron}/bin/todoist"
              "$mod, E, exec, ${pkgs.nautilus}/bin/nautilus"
              ", Print, exec, ${pkgs.grimblast}/bin/grimblast copy area"
            ]
            ++ keybindings.window-movement
            ++ keybindings.window-management
            ++ keybindings.switch-workspace;

          bindm = [
            # move/resize windows with $mod + l/r mouse
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          animations = {
            enabled = true;
            bezier = [
              "easeOutQuint,0.23,1,0.32,1"
              "easeInOutCubic,0.65,0.05,0.36,1"
              "linear,0,0,1,1"
              "almostLinear,0.5,0.5,0.75,1.0"
              "quick,0.15,0,0.1,1"
            ];
            animation = [
              "global, 1, 10, default"
              "border, 1, 5.39, easeOutQuint"
              "windows, 1, 4.79, easeOutQuint"
              "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
              "windowsOut, 1, 1.49, linear, popin 87%"
              "fadeIn, 1, 1.73, almostLinear"
              "fadeOut, 1, 1.46, almostLinear"
              "fade, 1, 3.03, quick"
              "layers, 1, 3.81, easeOutQuint"
              "layersIn, 1, 4, easeOutQuint, fade"
              "layersOut, 1, 1.5, linear, fade"
              "fadeLayersIn, 1, 1.79, almostLinear"
              "fadeLayersOut, 1, 1.39, almostLinear"
              "workspaces, 0, 0, ease"
            ];
          };

          decoration = {
            inactive_opacity = 0.90;
            fullscreen_opacity = 1.0;
            rounding = 8;
            blur = {
              enabled = true;
              size = 8;
              passes = 2;
            };
          };

          general = {
            gaps_in = 8;
            gaps_out = 24;
            border_size = 3;
          };

          input = {
            accel_profile = "flat";
            sensitivity = 0;
          };
        };

        systemd.variables = [ "--all" ];
      };
    };
  };
}
