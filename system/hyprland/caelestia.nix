{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos.desktop.hyprland;

  inherit (lib) mkIf;

  mod = "SUPER";

  cli =
    inputs.caelestia-shell.inputs.caelestia-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
  caelestia = "${cli}/bin/caelestia";

  # Repo-bundled wallpapers, copied into the store. caelestia owns the
  # background now that hyprpaper is retired.
  wallpapers = ../../wallpapers;

  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  sink = "@DEFAULT_AUDIO_SINK@";
  source = "@DEFAULT_AUDIO_SOURCE@";
  volumeStep = "5";
in
{
  config = mkIf cfg.enable {
    # caelestia is a full Quickshell desktop shell: it owns the bar, app
    # launcher, notifications, session menu, OSD and media controls. These
    # binds drive it over its IPC (`caelestia shell ...`), replacing the
    # rofi/swaync/swayosd/wlogout keybinds that lived in hyprland.nix. They
    # merge into the shared `binds` option, the same way swayosd used to.
    dusk.system.nixos.desktop.hyprland.binds = [
      # Panels & launcher
      {
        key = "${mod} + Space";
        exec = "${caelestia} shell drawers toggle launcher";
      }
      {
        key = "${mod} + escape";
        exec = "${caelestia} shell drawers toggle dashboard";
      }
      {
        key = "${mod} + CTRL + escape";
        exec = "${caelestia} shell drawers toggle session";
      }
      {
        key = "${mod} + SHIFT + escape";
        exec = "${caelestia} shell notifs clear";
        flags.locked = true;
      }

      # Manual lock (replaces the old hyprlock Pause bind). caelestia owns the
      # lockscreen now — the same lock its idle timeout and lock-before-sleep
      # use, so all locking goes through one path.
      {
        key = "Pause";
        exec = "${caelestia} shell lock lock";
      }

      # Clipboard history picker (replaces clipman+rofi); copies the chosen
      # entry then pastes it, preserving the old paste-on-pick behaviour.
      {
        key = "${mod} + SHIFT + V";
        exec = ''bash -c "${caelestia} clipboard && ${pkgs.wtype}/bin/wtype -M ctrl -M shift v"'';
      }

      # Volume (caelestia's OSD pops automatically on any PipeWire change)
      {
        key = "XF86AudioRaiseVolume";
        exec = "${wpctl} set-volume -l 1 ${sink} ${volumeStep}%+";
        flags = {
          locked = true;
          repeating = true;
        };
      }
      {
        key = "XF86AudioLowerVolume";
        exec = "${wpctl} set-volume ${sink} ${volumeStep}%-";
        flags = {
          locked = true;
          repeating = true;
        };
      }
      {
        key = "XF86AudioMute";
        exec = "${wpctl} set-mute ${sink} toggle";
        flags.locked = true;
      }
      {
        key = "XF86AudioMicMute";
        exec = "${wpctl} set-mute ${source} toggle";
        flags.locked = true;
      }

      # Brightness (caelestia's brightness IPC drives ddcutil/brightnessctl
      # and shows the OSD)
      {
        key = "XF86MonBrightnessUp";
        exec = "${caelestia} shell brightness set +${volumeStep}%";
        flags = {
          locked = true;
          repeating = true;
        };
      }
      {
        key = "XF86MonBrightnessDown";
        exec = "${caelestia} shell brightness set ${volumeStep}%-";
        flags = {
          locked = true;
          repeating = true;
        };
      }

      # Media keys
      {
        key = "XF86AudioPlay";
        exec = "${caelestia} shell mpris playPause";
        flags.locked = true;
      }
      {
        key = "XF86AudioNext";
        exec = "${caelestia} shell mpris next";
        flags.locked = true;
      }
      {
        key = "XF86AudioPrev";
        exec = "${caelestia} shell mpris previous";
        flags.locked = true;
      }
    ];

    home-manager.users.${config.dusk.username} =
      { lib, ... }:
      {
        imports = [ inputs.caelestia-shell.homeManagerModules.default ];

        programs.caelestia = {
          enable = true;

          # Started as a systemd user service bound to graphical-session.target,
          # which UWSM sets up for the Hyprland session (see hyprland.nix).
          systemd.enable = true;

          # Puts `caelestia` on PATH and enables full shell functionality.
          cli.enable = true;

          settings = {
            # Stick to the repo's Catppuccin Mocha instead of deriving a palette
            # from the wallpaper, and keep it stable when the wallpaper changes.
            services.smartScheme = false;

            # Always show temperatures in Celsius. caelestia guesses the weather
            # unit from the locale's measurement system, and our `en_US.UTF-8`
            # locale (system.locale, wired into LC_MEASUREMENT) resolves to US
            # Imperial — which defaults `useFahrenheit` to true and shows the
            # weather in °F. Pin both the weather and performance-sensor units
            # to Celsius explicitly so the locale can't flip them back.
            services.useFahrenheit = false;
            services.useFahrenheitPerformance = false;

            # Show the bar battery indicator by default (laptops); desktops force
            # it off per-host (see machines/battlecruiser.nix).
            bar.status.showBattery = lib.mkDefault true;

            # Wallpaper switcher browses the repo's bundled wallpapers.
            paths.wallpaperDir = "${wallpapers}";
          };
        };

        # caelestia draws and manages the wallpaper itself, so retire hyprpaper
        # (configured in both hyprland.nix and wallpapers.nix).
        services.hyprpaper.enable = lib.mkForce false;

        # Clipboard history daemon backing `caelestia clipboard` (replaces clipman).
        services.cliphist.enable = true;

        # caelestia keeps the active scheme and wallpaper as runtime state under
        # ~/.local/state/caelestia, not in shell.json. Seed them on first
        # activation only, so the desktop comes up themed (Catppuccin Mocha) with
        # a wallpaper, while `caelestia scheme`/`wallpaper` can still change them.
        home.activation.caelestiaDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          cstate="''${XDG_STATE_HOME:-$HOME/.local/state}/caelestia"

          # `scheme get` writes the built-in default (Catppuccin Mocha) into
          # scheme.json without running caelestia's external app-theming hooks.
          [ -e "$cstate/scheme.json" ] || ${caelestia} scheme get >/dev/null 2>&1 || true

          # --no-smart keeps the scheme above instead of recolouring from the image.
          [ -e "$cstate/wallpaper/path.txt" ] || ${caelestia} wallpaper -f ${wallpapers}/default.jpg --no-smart >/dev/null 2>&1 || true
        '';
      };
  };
}
