{ config, pkgs, ... }: {
  config = {
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

    # Run the homelab QEMU VM (the `nix run .#vm` from
    # ~/Code/cfcosta/homelab.nix) as a managed user service instead of a
    # foreground terminal. Linger is enabled for this user (see default.nix), so
    # WantedBy=default.target brings the VM up at boot without a login.
    #
    # `nix run` keeps it live: each (re)start rebuilds from the homelab
    # working copy — uncommitted changes included — exactly like running the
    # command by hand. So the update loop is: edit that flake, then
    # `systemctl --user restart homelab-vm`. Headless serial console lands in
    # the journal (`journalctl --user -u homelab-vm -f`); reach the guest over
    # Tailscale (`ssh homelab@100.111.10.36`) — it's on a NAT tap now, not a
    # SLIRP host-forward.
    home-manager.users.${config.dusk.username}.systemd.user.services.homelab-vm = {
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
  };
}
