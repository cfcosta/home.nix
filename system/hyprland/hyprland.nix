{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;
  inherit (builtins) concatLists genList toString;

  cfg = config.dusk.system.nixos.desktop.hyprland;

  launchTerm = cmd: ''${pkgs.ghostty}/bin/ghostty --class=com.mitchellh.ghostty.floating -e ${cmd}'';
  launchWeb =
    url: name: class:
    ''${pkgs.chromium}/bin/chromium --new-window --ozone-platform="wayland" --app="${url}" --name="${name}" --class="${class}"'';

  keybindings = {
    # Binds $mod + [shift +] {1...9} to [move to] workspace {1...9}
    switch-workspace = concatLists (
      genList (
        i:
        let
          ws = i + 1;
        in
        [
          "$mod, code:1${toString i}, workspace, ${toString ws}"
          "$mod SHIFT, code:1${toString i}, movetoworkspacesilent, ${toString ws}"
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
      "$mod SHIFT, Space, togglefloating"
      "$mod, F, fullscreen"
      "$mod, Q, killactive"
    ];
  };
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        XDG_CURRENT_DESKTOP = "Hyprland";
        XDG_SESSION_DESKTOP = "Hyprland";
      };

      systemPackages = with pkgs; [
        dunst
        grimblast
        rofi
      ];
    };

    programs = {
      dconf.enable = true;

      hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };
    };

    security.pam.services = {
      hyprlock = { };
      gdm.enableGnomeKeyring = true;
      gdm-password.enableGnomeKeyring = true;
    };

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
        "gnome"
        "gtk"
        "hyprland"
      ];

      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-wlr
      ];
    };

    home-manager.users.${config.dusk.username} = {
      dconf.enable = true;

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
        rofi.enable = true;
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

          bind = [
            "$mod, Space, exec, ${pkgs.rofi}/bin/rofi -show-icons -show drun"
            "$mod, Tab, exec, ${pkgs.dusk-keymap-switch}/bin/dusk-keymap-switch"

            ", Pause, exec, ${pkgs.hyprlock}/bin/hyprlock"
            ''$mod SHIFT, V, exec, bash -c "${pkgs.clipman}/bin/clipman pick -t rofi --err-on-no-selection && ${pkgs.wtype}/bin/wtype -M ctrl -M shift v"''

            # Screenshot
            "SHIFT, Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave screen"
            ", Print, exec, ${pkgs.grimblast}/bin/grimblast --notify copysave area"

            # System Applications
            "$mod, Return, exec, ${config.dusk.terminal.default}"
            "$mod, B, exec, ${config.dusk.defaults.browser}"
            "$mod, E, exec, ${pkgs.pcmanfm}/bin/pcmanfm"
            "$mod, P, exec, ${pkgs.pinta}/bin/pinta"

            # Notifications
            "$mod, escape, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -op"
            "$mod SHIFT, escape, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client --close-all"

            # Web Applications
            "$mod, D, exec, ${launchWeb "https://discord.com/channels/@me" "Discord" "discord"}"
            "$mod, C, exec, ${launchWeb "https://chatgpt.com" "ChatGPT" "chatgpt"}"
            "$mod, G, exec, ${launchWeb "https://github.com/notifications" "Github" "github"}"
            "$mod, W, exec, ${launchWeb "https://web.whatsapp.com" "Whatsapp Web" "whatsapp-web"}"
            "$mod, X, exec, ${launchWeb "https://x.com/compose/post" "X" "x.com"}"
            "$mod, Y, exec, ${launchWeb "https://www.youtube.com/feed/subscriptions" "Youtube" "youtube"}"
            "$mod SHIFT, F, exec, ${launchWeb "https://app.fastmail.com" "Fastmail" "fastmail"}"
            "$mod SHIFT, G, exec, ${launchWeb "https://grok.com" "Grok" "grok"}"

            "$mod, M, exec, ${config.dusk.defaults.music-player}"
            "$mod, O, exec, ${pkgs.obsidian}/bin/obsidian"
            "$mod, T, exec, ${pkgs.todoist-electron}/bin/todoist-electron"
            "$mod SHIFT, C, exec, ${pkgs.gnome-calculator}/bin/gnome-calculator"
            "$mod SHIFT, E, exec, org.gnome.Fractal"
            "$mod SHIFT, T, exec, ${pkgs.streamlink-twitch-gui-bin}/bin/streamlink-twitch-gui"

            # $mod + ctrl = system configuration
            "$mod CTRL, escape, exec, ${pkgs.wlogout}/bin/wlogout"
            "$mod CTRL, A, exec, ${pkgs.pavucontrol}/bin/pavucontrol"
            "$mod CTRL, B, exec, ${pkgs.blueberry}/bin/blueberry"
            "$mod CTRL, D, exec, ${launchTerm "${pkgs.lazydocker}/bin/lazydocker"}"
            "$mod CTRL, E, exec, ${launchTerm "${pkgs.yazi}/bin/yazi"}"
            "$mod CTRL, N, exec, ${pkgs.networkmanagerapplet}/bin/nm-connection-editor"
            "$mod CTRL, P, exec, ${pkgs.helvum}/bin/helvum"
            "$mod CTRL, S, exec, ${launchTerm "${pkgs.btop}/bin/btop"}"
            "$mod CTRL, W, exec, ${launchTerm "${pkgs.nm-wifi}/bin/nm-wifi"}"
          ]
          ++ (optionals config.dusk.system.nixos.desktop.gaming.enable [
            "$mod SHIFT, S, exec, ${pkgs.steam}/bin/steam"
          ])
          ++ keybindings.window-movement
          ++ keybindings.window-management
          ++ keybindings.switch-workspace;

          bindm = [
            # Move/resize windows with $mod + l/r mouse
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

          exec-once = [
            "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh"
          ];

          general = {
            gaps_in = 8;
            gaps_out = 24;
            border_size = 3;
          };

          input = {
            accel_profile = "flat";
            sensitivity = 0;
          };

          windowrulev2 = [
            "float, class:^(com.mitchellh.ghostty.floating)$"
            "float, class:^(org.gnome.Calculator)$"
          ];
        };

        systemd.variables = [ "--all" ];
      };
    };
  };
}
