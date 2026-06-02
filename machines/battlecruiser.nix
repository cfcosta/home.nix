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

        # Desktop idle: lock only after 2h of inactivity, nothing sooner.
        # caelestia's defaults lock at 3min, blank the screen at 5min and
        # suspend-then-hibernate at 10min — none of which we want on an
        # always-on desktop. This single entry replaces that whole list, so
        # the monitor stays on and the box never auto-suspends.
        general.idle.timeouts = [
          {
            timeout = 7200;
            idleAction = "lock";
          }
        ];
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
