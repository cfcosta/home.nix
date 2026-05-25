{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos.desktop.hyprland;

  inherit (lib) mkForce mkIf;

  mod = "SUPER";

  cli = inputs.caelestia-shell.inputs.caelestia-cli.packages.${pkgs.system}.default;
  caelestia = "${cli}/bin/caelestia";

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

    home-manager.users.${config.dusk.username} = {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      programs.caelestia = {
        enable = true;

        # Started as a systemd user service bound to graphical-session.target,
        # which UWSM sets up for the Hyprland session (see hyprland.nix).
        systemd.enable = true;

        # Puts `caelestia` on PATH and enables full shell functionality.
        cli.enable = true;
      };

      # caelestia draws and manages the wallpaper itself, so retire hyprpaper
      # (configured in both hyprland.nix and wallpapers.nix). Set a wallpaper
      # once with `caelestia wallpaper -f <path>` to also generate the scheme.
      services.hyprpaper.enable = mkForce false;

      # Clipboard history daemon backing `caelestia clipboard` (replaces clipman).
      services.cliphist.enable = true;
    };
  };
}
