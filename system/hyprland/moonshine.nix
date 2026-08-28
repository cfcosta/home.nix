{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionals;

  cfg = config.dusk.system.nixos.desktop.moonshine;
  emulation = config.dusk.system.nixos.desktop.emulation;
  gaming = config.dusk.system.nixos.desktop.gaming;

  inherit (config.dusk) username;

  # Declared in system/nixos/default.nix, so it is known at evaluation time.
  uid = config.users.users.${username}.uid;

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
  dolphin = "/run/current-system/sw/bin/dolphin-emu";
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
  # No import: services.moonshine is a nixpkgs module now
  # (nixos/modules/services/networking/moonshine.nix), so it is already in the
  # default module list. The flake input is kept only for its package build,
  # see `package` below.
  config = mkIf cfg.enable {
    services.moonshine = {
      enable = true;

      # nixpkgs packages the v0.15.0 release; the flake input is pinned past
      # it, and the commits in between carry fixes this host runs on — a
      # PulseAudio client crash that took the whole session down, an audio
      # timerfd wakeup fix, Heroic library discovery plus GOG install-state
      # reading (which the heroic scanner below depends on), and low-latency
      # Vulkan encoding. Drop this line and the flake input once nixpkgs
      # carries a release containing them; everything else here is upstream's
      # module unmodified.
      package = inputs.moonshine.packages.${pkgs.stdenv.hostPlatform.system}.moonshine;

      # Streamed applications are launched inside this user's systemd instance,
      # so it has to be the user owning the Steam library.
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
          # The emulators emulation.nix installs, when it is on. All four
          # are launched bare, which brings up their own game-list UI on the
          # streamed display: moonshine ships no emulator scanner (only
          # Steam, Desktop, Lutris and Heroic), and no ROM library is
          # described anywhere in this config, so per-game entries cannot be
          # generated from here. RetroArch is comfortable that way — its menu
          # is gamepad-driven and emulation.nix already points its browser at
          # the ROM library, so a controller alone reaches a game. Eden, RPCS3
          # and Dolphin are not: picking a game in any of them means driving a
          # desktop UI, so the client needs a pointer for those three.
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
            {
              title = "Dolphin";
              command = [ dolphin ];
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
      # without lowering the rest of moonshine's logging. This overrides the
      # module's own MOONSHINE_LOG default.
      environment.MOONSHINE_LOG = "moonshine=info,moonshine_core::tls=error";
    };

    # The GameStream ports: pairing/HTTPS/RTSP over TCP, video/control/audio
    # over UDP. Opened globally rather than through the module's
    # firewallInterfaces, which would mean naming battlecruiser's links
    # (eno1/wlp7s0) in a file every gaming host shares. GameStream traffic is
    # not fully encrypted, so this is only acceptable behind the home router —
    # the same posture gaming.nix already takes with Steam remote play and
    # local network game transfers. Streaming over Tailscale needs none of it:
    # networking.nix already trusts tailscale0 outright. The numbers are the
    # daemon's defaults, which `settings` above leaves alone.
    networking.firewall = {
      allowedTCPPorts = [
        47984
        47989
        48010
      ];
      allowedUDPPorts = [
        47998
        47999
        48000
      ];
    };

    # Two things upstream's flake module did that the nixpkgs one does not,
    # restored here so the service behaves as it did before the switch.
    systemd.services.moonshine = {
      # The user manager owns the runtime dir, the session bus, and the
      # transient units moonshine launches applications as. nixpkgs orders the
      # service after network.target only and resolves the runtime dir inside
      # ExecStart, which leaves a boot race: lingering brings user@<uid>.service
      # up as well, but nothing sequences the two, so moonshine can start before
      # /run/user/<uid>/bus exists and fall into its restart loop.
      requires = optionals (uid != null) [ "user@${toString uid}.service" ];
      after = optionals (uid != null) [ "user@${toString uid}.service" ];

      # /dev/dri/card* is video-group on NixOS and this user is deliberately not
      # in that group, so the service would otherwise lose access it had before.
      # This merges with, rather than replaces, the module's own
      # SupplementaryGroups: systemd's option type concatenates lists.
      serviceConfig.SupplementaryGroups = [ "video" ];
    };

    # Scoped by the polkit rule shipped in the package: lets moonshine hold a
    # block-type sleep inhibitor for the duration of a stream, so the host does
    # not suspend out from under a session (settings.inhibit_sleep is on by
    # default). Without it moonshine logs a warning and streams anyway. It has
    # to sit on the *user*, not the unit's SupplementaryGroups, because polkit
    # resolves subject.isInGroup() through NSS rather than the process's own
    # credentials — the module's SupplementaryGroups entry alone would not
    # satisfy the rule.
    #
    # The `input` group (read access to /dev/input/event*, needed when
    # streaming with no desktop session, since the streamed game has to read
    # the virtual gamepad moonshine creates) comes from the module itself now.
    users.users.${username}.extraGroups = [ "moonshine" ];
  };
}
