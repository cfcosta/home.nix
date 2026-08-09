{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib) mkIf optionals;

  cfg = config.dusk.system.nixos.desktop.moonshine;
  emulation = config.dusk.system.nixos.desktop.emulation;
  gaming = config.dusk.system.nixos.desktop.gaming;

  inherit (config.dusk) username;

  # Launchers are named by their /run/current-system/sw/bin path rather than a
  # store path, for two reasons. Moonshine resolves commands against the system
  # unit's PATH (systemd's default, not a login shell's), so a bare `steam`
  # would not resolve; and a store path would change the generated config on
  # every Steam/Heroic bump, restarting the service each time. Steam in
  # particular *must* come from the system path: programs.steam installs an FHS
  # wrapper carrying protontricks and the proton-cachyos compat packages, which
  # a plain pkgs.steam would not. The emulators land on the same path from
  # emulation.nix's environment.systemPackages, so the same reasoning applies.
  steam = "/run/current-system/sw/bin/steam";
  heroic = "/run/current-system/sw/bin/heroic";
  retroarch = "/run/current-system/sw/bin/retroarch";
  eden = "/run/current-system/sw/bin/eden";
  rpcs3 = "/run/current-system/sw/bin/rpcs3";
  bash = "/run/current-system/sw/bin/bash";

  # Steam is single-instance per user. When moonshine starts Steam inside its
  # own compositor while a desktop Steam is already running, the steam:// URL is
  # handed to that existing instance instead: Big Picture opens on the host's
  # physical monitor and the stream fails outright, which Moonlight surfaces as
  # a 503. Upstream's recommended workaround (TIPS.md, issue #134) is to ask any
  # running Steam to shut down and wait for it to actually exit before the
  # streamed instance launches. The trade-off is explicit and worth knowing:
  # starting a stream closes whatever Steam session is open on the desktop.
  #
  # PATH is set rather than inherited because this runs as ExecStartPre on a
  # transient systemd unit, which gets systemd's default PATH, not a login
  # shell's — bare `pgrep` would not resolve there. Only the argv[0] above needs
  # to be absolute for moonshine's own `which` lookup.
  #
  # Upstream waits up to 30s, which cannot work against moonshine's own
  # defaults. pre_command becomes ExecStartPre on a transient Type=exec unit, so
  # the systemd start job does not complete until it returns, and moonshine
  # bounds that job by launch_timeout_secs — which defaults to 2. A 30s wait
  # would abort every launch in exactly the situation the recipe exists to fix.
  # Raising the ceiling is therefore required, but it is deliberately kept
  # modest: moonshine spends the same value again after launch watching for the
  # unit to fail, and that one elapses in full on success, so every extra second
  # here is a second of dead time on every start. Ten seconds covers a normal
  # `steam -shutdown`, and the 15s ceiling leaves the start job headroom while
  # overlapping Big Picture's own cold start. Neither knob is mentioned in
  # upstream's README or TIPS.md.
  steamShutdownWait = 10;
  steamLaunchTimeout = 15;

  closeDesktopSteam = [
    bash
    "-c"
    ''
      export PATH=/run/current-system/sw/bin
      if pgrep -x steam >/dev/null; then
        steam -shutdown >/dev/null 2>&1
        for _ in $(seq 1 ${toString steamShutdownWait}); do
          pgrep -x steam >/dev/null || break
          sleep 1
        done
      fi
    ''
  ];
in
{
  imports = [ inputs.moonshine.nixosModules.default ];

  config = mkIf cfg.enable {
    services.moonshine = {
      enable = true;

      # Streamed applications are launched inside this user's systemd instance,
      # so it has to be the user owning the Steam library. The module derives
      # the uid it needs from users.users.<user>.uid, which is why that is
      # declared explicitly in system/nixos/default.nix.
      user = username;

      # Moonlight clients show this in their host list.
      settings = {
        name = config.dusk.system.hostname;

        # A single entry that opens Steam Big Picture — the couch UI, and the
        # way to reach anything the scanner below misses (non-Steam shortcuts,
        # store, settings). Upstream's default application list points at
        # /usr/bin/steam, which does not exist here, so this replaces it
        # wholesale.
        application =
          optionals config.programs.steam.enable [
            {
              title = "Steam";
              command = [
                steam
                "steam://open/bigpicture"
              ];
              pre_command = [ closeDesktopSteam ];
              launch_timeout_secs = steamLaunchTimeout;
            }
          ]
          # The emulators emulation.nix installs, when it is on. All three
          # are launched bare, which brings up their own game-list UI on the
          # streamed display: moonshine ships no emulator scanner (only
          # Steam, Desktop, Lutris and Heroic), and no ROM library is
          # described anywhere in this config, so per-game entries cannot be
          # generated from here. RetroArch is comfortable that way — its menu
          # is gamepad-driven and emulation.nix already points its browser at
          # the ROM library, so a controller alone reaches a game. Eden and
          # RPCS3 are not: picking a game in either means driving a desktop
          # UI, so the client needs a pointer for those two.
          ++ optionals emulation.enable [
            {
              title = "RetroArch";
              command = [ retroarch ];
            }
            {
              title = "Eden";
              command = [ eden ];
            }
            {
              title = "RPCS3";
              command = [ rpcs3 ];
            }
          ];

        # Scanners keep the Moonlight app list in sync with what is actually
        # installed, so games do not have to be enumerated here by hand. Only
        # the launchers gaming.nix installs are scanned; the desktop scanner is
        # deliberately left out, since it would list every .desktop file on the
        # system (Blender, Firefox, ...) as a streamable "game".
        application_scanner =
          optionals config.programs.steam.enable [
            {
              type = "steam";
              # NixOS's Steam uses the default library location.
              library = "$HOME/.local/share/Steam";
              command = [
                steam
                "-bigpicture"
                "steam://rungameid/{game_id}"
              ];
              # Every scanned game launches through a steam:// URL too, so it
              # hits the same single-instance forwarding problem as the Big
              # Picture entry above. The scanner applies this to each
              # application it produces.
              pre_command = [ closeDesktopSteam ];
              launch_timeout_secs = steamLaunchTimeout;
            }
          ]
          ++ optionals gaming.enable [
            {
              type = "heroic";
              command = [
                heroic
                "--no-gui"
                "heroic://launch?appName={app_name}&runner={runner}"
              ];
            }
          ];
      };

      # A Moonlight client sitting idle on its Computers screen probes the HTTPS
      # port every 5s and drops the connection, and each probe logs a TLS
      # handshake WARN. Silencing that one target keeps the journal readable
      # without lowering the rest of moonshine's logging.
      logFilter = "moonshine=info,moonshine_core::tls=error";

      # Open the GameStream ports (pairing/HTTPS/RTSP over TCP, video/control/
      # audio over UDP). GameStream traffic is not fully encrypted, so upstream
      # limits this to LAN or VPN-facing firewalls — which is exactly the case
      # here: this host is behind the home router, and it matches the posture
      # gaming.nix already takes with Steam remote play and local network game
      # transfers. Streaming over Tailscale needs none of this, since
      # networking.nix already trusts tailscale0 outright.
      openFirewall = true;
    };

    users.users.${username}.extraGroups = [
      # Read access to /dev/input/event*, needed only when streaming headless:
      # moonshine creates a virtual gamepad per connected controller, and the
      # streamed game has to be able to read it. With an active desktop session
      # the seat ACLs already grant this, so drop this group if you never stream
      # from a logged-out machine — it also lets any process running as this
      # user read every keystroke on the host.
      "input"

      # Scoped by the polkit rule shipped in the package: lets moonshine hold a
      # block-type sleep inhibitor for the duration of a stream, so the host
      # does not suspend out from under a session (settings.inhibit_sleep is on
      # by default). Without it moonshine logs a warning and streams anyway.
      "moonshine"
    ];
  };
}
