{ config, lib, ... }: {
  config = {
    dusk.system.nixos.desktop = {
      gaming.enable = true;

      hyprland = {
        enable = true;

        binds =
          map
            (i: {
              key = "SUPER + CTRL + ${toString i}";
              dispatch = "focus({ workspace = ${toString i}, on_current_monitor = true })";
            })
            [
              1
              2
              3
              4
              5
              6
            ];
      };
    };

    home-manager.users.${config.dusk.username} = {
      programs.caelestia.settings = {
        # Desktop — no battery, so hide caelestia's bar battery indicator.
        bar.status.showBattery = lib.mkForce false;

        # Render the bar on every monitor. caelestia's bar is a left-edge
        # vertical strip (its only supported placement — there's no
        # right-side option), and an empty `excludedScreens` is the default,
        # so dropping the previous `[ "DP-4" ]` exclusion brings the bar back
        # onto the portrait monitor alongside HDMI-A-2.

        # Desktop idle: no automatic actions at all. caelestia's defaults
        # lock at 3min, blank the screen at 5min and suspend-then-hibernate
        # at 10min; we previously kept a 2h auto-lock, but any monitor
        # disconnect/reconnect while locked (the Samsung HPD-drop issue)
        # breaks the lock surface, and the monitor-heal listener then
        # restarts caelestia — killing the lockscreen entirely. Until that's
        # solid, locking is manual only (Pause bind in caelestia.nix). An
        # empty list fully replaces the defaults, so nothing idles.
        general.idle.timeouts = [ ];

        # Same reasoning for the lock-before-sleep hook (upstream default
        # true): resume re-handshakes the displays, which is exactly the
        # disconnect/reconnect path that breaks the lock.
        general.idle.lockBeforeSleep = false;
      };
    };
  };
}
