{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
  ];

  config = {
    boot = {
      initrd.kernelModules = [ "kvm-amd" ];
      # kernelPackages = pkgs.linuxPackages_xanmod_latest;
    };

    networking.resolvconf.extraConfig = ''
      name_servers_append="1.1.1.1 1.0.0.1"
      resolv_conf_options="edns0 timeout:1 attempts:2"
    '';

    services.tailscale.extraSetFlags = [ "--accept-dns=false" ];

    networking.networkmanager = {
      ethernet.macAddress = "permanent";
      wifi.scanRandMacAddress = false;

      # Re-apply the Intel I225-V workarounds whenever NetworkManager brings
      # the link up. This NIC can silently stop passing traffic after hours of
      # uptime when Energy Efficient Ethernet/offloads are left enabled.
      dispatcherScripts = [
        {
          type = "basic";
          source = pkgs.writeShellScript "eno1-link-workarounds" ''
            if [ "$1" = "eno1" ] && [ "$2" = "up" ]; then
              ${pkgs.ethtool}/bin/ethtool --set-eee eno1 eee off || true
              ${pkgs.ethtool}/bin/ethtool -K eno1 tso off gso off gro off || true
            fi
          '';
        }
      ];
    };

    systemd.services.disable-eno1-eee = {
      description = "Disable EEE/offloads on eno1 (Intel I225-V silent-stall workaround)";
      after = [ "sys-subsystem-net-devices-eno1.device" ];
      bindsTo = [ "sys-subsystem-net-devices-eno1.device" ];
      wantedBy = [ "sys-subsystem-net-devices-eno1.device" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.ethtool}/bin/ethtool --set-eee eno1 eee off || true
        ${pkgs.ethtool}/bin/ethtool -K eno1 tso off gso off gro off || true
      '';
    };

    # ---- homelab VM: NAT tap bridge (replaces the VM's QEMU SLIRP net) ----
    # The homelab VM (the homelab-vm user service below) used QEMU user-mode
    # (SLIRP) networking, which accepts no inbound connections — so qBittorrent
    # inside the VM was unconnectable (0 upload, ~1 of each swarm's peers) and
    # crawled. This gives it a private point-to-point tap with NAT instead:
    # native throughput, plus a DNAT so peers that reach THIS host on the torrent
    # port are forwarded into the guest. eno1 and its I225-V silent-stall
    # workarounds are deliberately left untouched — that's why this is a NAT tap
    # and not an eno1 bridge.
    #
    # Still required for PUBLIC inbound: a port-forward on the home router
    # (201.92.109.196 → 10.0.0.2, tcp+udp 45971). Outbound and native throughput
    # work without it; only internet peers dialing in need the router rule.

    # A persistent tap the unprivileged QEMU (a user service) can open, with the
    # host end of the point-to-point link at 10.100.0.1. `user` is the account the
    # homelab-vm service runs as, so it may open the tap without CAP_NET_ADMIN.
    systemd.services.homelab-vm-tap = {
      description = "Persistent tap + host address for the homelab VM bridge";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-pre.target" ];
      path = [ pkgs.iproute2 ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "homelab-vm-tap-up" ''
          ip tuntap add dev vm0 mode tap user ${config.dusk.username} 2>/dev/null || true
          ip addr replace 10.100.0.1/24 dev vm0
          ip link set vm0 up
        '';
        ExecStop = pkgs.writeShellScript "homelab-vm-tap-down" ''
          ip link del vm0 2>/dev/null || true
        '';
      };
    };

    # DHCP for the guest on the tap (DHCP only; `--port=0` disables its DNS so it
    # can't clash with the host resolver). The guest keeps its NetworkManager DHCP
    # unchanged and always gets 10.100.0.2 / gateway 10.100.0.1 / public DNS.
    systemd.services.homelab-vm-dhcp = {
      description = "DHCP for the homelab VM tap";
      wantedBy = [ "multi-user.target" ];
      after = [ "homelab-vm-tap.service" ];
      requires = [ "homelab-vm-tap.service" ];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --port=0 \
            --interface=vm0 --bind-interfaces \
            --dhcp-range=10.100.0.2,10.100.0.2,255.255.255.0,12h \
            --dhcp-option=option:router,10.100.0.1 \
            --dhcp-option=option:dns-server,1.1.1.1,1.0.0.1
        '';
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Masquerade the VM's subnet out eno1 and DNAT the torrent port to the guest.
    # (Leaves the existing docker/podman NAT alone — different source interfaces.)
    networking.nat = {
      enable = true;
      externalInterface = "eno1";
      internalInterfaces = [ "vm0" ];
      forwardPorts = [
        {
          sourcePort = 45971;
          proto = "tcp";
          destination = "10.100.0.2:45971";
        }
        {
          sourcePort = 45971;
          proto = "udp";
          destination = "10.100.0.2:45971";
        }
      ];
    };

    # NetworkManager must not touch the tap; trust host<->guest traffic on it.
    networking.networkmanager.unmanaged = [ "interface-name:vm0" ];
    networking.firewall.trustedInterfaces = [ "vm0" ];

    dusk = {
      fonts.monospace = "Berkeley Mono NerdFont Mono";

      terminal.font-size = 12;

      shell.starship.disabledModules = [
        "cmd_duration"
        "dart"
        "fossil_branch"
        "fossil_metrics"
        "git_branch"
        "git_commit"
        "git_metrics"
        "git_state"
        "git_status"
        "gradle"
        "guix_shell"
        "hg_branch"
        "java"
        "package"
        "package"
        "pijul_channel"
        "vagrant"
      ];

      system = {
        hostname = "battlecruiser";

        monitors = [
          {
            name = "DP-4";

            bitDepth = 10;
            position = {
              x = 0;
              y = 0;
            };
            refreshRate = 239.96;
            resolution = {
              width = 2560;
              height = 1440;
            };
            scale = 1.0;
            transform = {
              rotate = 90;
              flipped = false;
            };
            vrr = true;
          }
          {
            name = "HDMI-A-2";

            bitDepth = 10;
            position = {
              x = 1440;
              y = 2560 - 2160;
            };
            refreshRate = 119.88;
            resolution = {
              width = 3840;
              height = 2160;
            };
            scale = 1.0;
            transform = {
              rotate = 0;
              flipped = false;
            };
            vrr = true;
          }
        ];

        nixos.desktop = {
          gaming.enable = true;
          hyprland.enable = true;
        };
      };
    };

    # Keep this user's systemd instance running at boot and across logouts, so
    # the homelab-vm and jobcrawler units (user services, defined below) are
    # genuinely always-on rather than tied to a graphical login — without
    # lingering, user units start at first login and are torn down when the
    # last session ends. Linger was already on here (set by hand via
    # `loginctl enable-linger`); declaring it makes that reproducible and
    # self-healing on activation.
    users.users.${config.dusk.username}.linger = true;

    home-manager.users.${config.dusk.username} = {
      home.file.".XCompose".text = ''
        include "%L"

        <dead_acute> <c> : "ç" U00E7
        <dead_acute> <C> : "Ç" U00C7
      '';

      home.sessionVariables = {
        XCOMPOSEFILE = "${config.dusk.folders.home}/.XCompose";
        XKB_DEFAULT_COMPOSE_FILE = "${config.dusk.folders.home}/.XCompose";
      };

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
        # breaks the lock surface, and the monitor-heal listener below then
        # restarts caelestia — killing the lockscreen entirely. Until that's
        # solid, locking is manual only (Pause bind in caelestia.nix). An
        # empty list fully replaces the defaults, so nothing idles.
        general.idle.timeouts = [ ];

        # Same reasoning for the lock-before-sleep hook (upstream default
        # true): resume re-handshakes the displays, which is exactly the
        # disconnect/reconnect path that breaks the lock.
        general.idle.lockBeforeSleep = false;
      };

      # Run the homelab QEMU VM (the `nix run .#vm` from
      # ~/Code/cfcosta/homelab.nix) as a managed user service instead of a
      # foreground terminal. Linger is enabled for this user, so
      # WantedBy=default.target brings the VM up at boot without a login.
      #
      # `nix run` keeps it live: each (re)start rebuilds from the homelab
      # working copy — uncommitted changes included — exactly like running the
      # command by hand. So the update loop is: edit that flake, then
      # `systemctl --user restart homelab-vm`. Headless serial console lands in
      # the journal (`journalctl --user -u homelab-vm -f`); reach the guest over
      # Tailscale (`ssh homelab@100.111.10.36`) — it's on a NAT tap now, not a
      # SLIRP host-forward.
      systemd.user.services.homelab-vm = {
        Unit.Description = "homelab NixOS configuration in a QEMU VM";

        Service = {
          # WorkingDirectory must be the repo: the VM runner resolves its
          # persistent disk (`./data/homelab.qcow2`, see homelab's
          # modules/vm.nix) against the launch dir, and `.#vm` resolves `.` to
          # the cwd. PATH carries git for nix's local-flake evaluation.
          WorkingDirectory = "${config.dusk.folders.code}/cfcosta/homelab.nix";
          Environment = "PATH=/run/current-system/sw/bin";

          # The same Determinate Nix used interactively (flakes already on).
          # Build with a persistent out-link (a GC root) instead of `nix run`:
          # the guest mounts the host /nix/store over 9p, so a host
          # `nix-collect-garbage` deleting the closure a running VM booted
          # from hangs the guest (dead SSH shell, apps losing libraries).
          ExecStart = "/run/current-system/sw/bin/sh -c 'nix build .#vm --out-link %h/.local/state/homelab-vm-gcroot && exec %h/.local/state/homelab-vm-gcroot/bin/run-homelab-vm'";

          # A guest poweroff (qemu exits 0) stays down; a crash or a failed
          # build comes back after a pause. Switch to "always" if you'd rather a
          # clean guest poweroff reboot the VM too.
          Restart = "on-failure";
          RestartSec = 15;

          # Stop/restart shuts the guest down cleanly over SSH rather than
          # yanking qemu's power. The unencrypted ~/.ssh/id_ed25519 is an
          # authorized key for the wheel `homelab` user (passwordless sudo),
          # reached over Tailscale now (the VM no longer SLIRP-forwards :22 to
          # host :2222). Host-key checking is off because the VM regenerates a
          # throwaway host key every boot. If the
          # guest doesn't answer SSH, the script returns and systemd's normal
          # SIGTERM kills qemu — the old hard power-off, now only a fallback.
          # The wait loop blocks until the VM process actually exits, so
          # TimeoutStopSec below must outlast it before systemd forces the kill.
          ExecStop = "${pkgs.writeShellScript "homelab-vm-graceful-stop" ''
            gssh() {
              ${pkgs.openssh}/bin/ssh -nF /dev/null \
                -i ${config.dusk.folders.home}/.ssh/id_ed25519 \
                -o IdentitiesOnly=yes -o IdentityAgent=none \
                -o PreferredAuthentications=publickey -o BatchMode=yes \
                -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
                -o UserKnownHostsFile=/dev/null \
                homelab@100.111.10.36 "$@"
            }

            # Only try a clean shutdown if the guest actually answers SSH;
            # otherwise fall straight through to systemd's SIGTERM fallback.
            if gssh true 2>/dev/null; then
              # poweroff tears down the connection, so its exit status is
              # meaningless — fire it and wait on the VM process instead.
              gssh 'sudo -n systemctl poweroff' 2>/dev/null || true
              pid=$MAINPID
              for (( i = 0; i < 90; i++ )); do
                kill -0 "$pid" 2>/dev/null || exit 0
                ${pkgs.coreutils}/bin/sleep 1
              done
            fi
            exit 0
          ''}";

          # Cover the SSH graceful-shutdown wait above before the force-kill.
          TimeoutStopSec = 120;
        };

        Install.WantedBy = [ "default.target" ];
      };

      # Run the jobcrawler daemon (~/Code/cfcosta/jobcrawler: crawl fleet,
      # LLM match scoring, web UI on :8765) as a managed user service, same
      # always-on pattern as homelab-vm above (linger brings it up at boot).
      #
      # `nix develop -c` is load-bearing: the daemon needs the repo flake's dev
      # shell (editable install; bare .venv python lacks libstdc++ for
      # tokenizers on NixOS), and since the install is editable each restart
      # picks up the working copy — edit, then
      # `systemctl --user restart jobcrawler`. Logs land in the journal
      # (`journalctl --user -u jobcrawler -f`).
      systemd.user.services.jobcrawler = {
        Unit.Description = "jobcrawler daemon (crawl + match scoring + web UI on :8765)";

        Service = {
          # The live SQLite DB (jobcrawler.db) is resolved relative to the
          # daemon's cwd, so the working directory must be the repo root.
          WorkingDirectory = "${config.dusk.folders.code}/cfcosta/jobcrawler";

          # PATH carries git for nix's local-flake evaluation (same reason as
          # homelab-vm). PYTHONUNBUFFERED because the generation pipeline's
          # diagnostics are print()s — block-buffered through pipes, they'd be
          # invisible in the journal and lost on a kill.
          Environment = [
            "PATH=/run/current-system/sw/bin"
            "PYTHONUNBUFFERED=1"
          ];

          # Model choice, rate/concurrency/cap knobs and the API keys live in
          # a mode-600 file OUTSIDE the store and the repo (secrets). Systemd
          # reads plain KEY=value lines — no `export`/`set -a` needed (that
          # shell subtlety once left the daemon silently running on default
          # model and cap). Retune by editing the file and restarting the
          # unit; no rebuild.
          EnvironmentFile = "%h/.config/jobcrawler/daemon.env";

          ExecStart = "/run/current-system/sw/bin/sh -c 'exec nix develop -c python -m jobcrawler.cli run --host 0.0.0.0'";

          # The daemon should simply always be up; RestartSec gives a crashed
          # LLM backend or a half-written working copy a moment to settle.
          Restart = "always";
          RestartSec = 15;

          # SIGTERM is held until the current scheduler tick finishes, and a
          # generation-heavy tick can hold it for many minutes — don't wait it
          # out on stop/restart. SIGKILL after 30s is safe: the store is
          # SQLite in WAL mode and every in-flight LLM grant was reserved up
          # front, so a hard kill loses nothing but the interrupted pass.
          TimeoutStopSec = 30;
        };

        Install.WantedBy = [ "default.target" ];
      };
    };

    dusk.system.nixos.desktop.hyprland.binds =
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

    dusk.system.nixos.desktop.hyprland.extraLuaConfig = ''
      hl.env("XCOMPOSEFILE",            "${config.dusk.folders.home}/.XCompose")
      hl.env("XKB_DEFAULT_COMPOSE_FILE", "${config.dusk.folders.home}/.XCompose")

      hl.config({
        input = {
          kb_layout  = "us,us",
          kb_variant = ",intl",
          kb_options = "grp:alt_shift_toggle",
        },
      })

      for _, ws in ipairs({ "1", "2", "3" }) do
        hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-2" })
      end
      for _, ws in ipairs({ "4", "5", "6" }) do
        hl.workspace_rule({ workspace = ws, monitor = "DP-4" })
      end
    '';

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/267a2e89-f17c-4ae8-ba84-709fda2a95aa";
        fsType = "ext4";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/0B55-0450";
        fsType = "vfat";
      };

      "/media" = {
        device = "/dev/disk/by-uuid/12cdcfc5-77b8-4182-994d-a081c22669dd";
        fsType = "ext4";
      };
    };

    swapDevices = [ ];
  };
}
