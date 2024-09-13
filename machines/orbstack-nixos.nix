{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  inherit (lib) hasPrefix optionals;
in
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];

  config = {
    dusk = {
      system = {
        hostname = "orbstack-nixos";

        nixos = {
          createUser = false;

          bittorrent.enable = false;
          bootloader.enable = false;
          desktop.enable = false;
          networking.enable = false;
          nvidia.enable = false;
          virtualisation.enable = false;
        };
      };
    };

    age.identityPaths = [
      "${config.dusk.folders.home}/.ssh/id_ed25519"
      "/etc/ssh/ssh_host_ed25519_key"
    ];

    environment = {
      etc."resolv.conf".source = "/opt/orbstack-guest/etc/resolv.conf";

      shellInit = ''
        . /opt/orbstack-guest/etc/profile-early
        . /opt/orbstack-guest/etc/profile-late
      '';
    };

    # indicate builder support for emulated architectures
    nix.settings.extra-platforms = optionals (hasPrefix "x86_64" pkgs.system) [
      "x86_64-linux"
      "i686-linux"
    ];

    programs.ssh.extraConfig = ''
      Include /opt/orbstack-guest/etc/ssh_config
    '';

    security = {
      # Orbstack Certificate
      pki.certificates = [
        ''
          -----BEGIN CERTIFICATE-----
          MIICDDCCAbKgAwIBAgIQeac7gsmrsL9OscDn+lNJ8jAKBggqhkjOPQQDAjBmMR0w
          GwYDVQQKExRPcmJTdGFjayBEZXZlbG9wbWVudDEeMBwGA1UECwwVQ29udGFpbmVy
          cyAmIFNlcnZpY2VzMSUwIwYDVQQDExxPcmJTdGFjayBEZXZlbG9wbWVudCBSb290
          IENBMB4XDTIzMTExNjIzMDAwM1oXDTMzMTExNjIzMDAwM1owZjEdMBsGA1UEChMU
          T3JiU3RhY2sgRGV2ZWxvcG1lbnQxHjAcBgNVBAsMFUNvbnRhaW5lcnMgJiBTZXJ2
          aWNlczElMCMGA1UEAxMcT3JiU3RhY2sgRGV2ZWxvcG1lbnQgUm9vdCBDQTBZMBMG
          ByqGSM49AgEGCCqGSM49AwEHA0IABL3g0uB8X+igdcCvz0ze25e0lo1pUJLhD4JK
          b3V50XWs6Zw8pfRmQftN19Yuo4TOP5JLkvLh9p2YFqtQZPB1Qy+jQjBAMA4GA1Ud
          DwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5/s7RNYfRY2FH
          sCOoNfyQXjtPcDAKBggqhkjOPQQDAgNIADBFAiApJ2/Sgebsc+/2Mz9OWFefuN0J
          /cKLWhb3w4F8roq1XgIhAJQM8QpGqo9t5zt7nClzsOu5p9+hqWemjEYVDwvArRHi
          -----END CERTIFICATE-----
        ''
      ];

      sudo.wheelNeedsPassword = false;

    };

    services = {
      resolved.enable = false;
      openssh.enable = lib.mkForce false;
    };

    networking = {
      dhcpcd = {
        enable = false;

        extraConfig = ''
          noarp
          noipv6
        '';
      };

      useDHCP = false;
      useHostResolvConf = false;
      useNetworkd = false;
    };

    systemd = {
      network = {
        enable = true;
        networks."50-eth0" = {
          matchConfig.Name = "eth0";
          networkConfig = {
            DHCP = "ipv4";
            IPv6AcceptRA = true;
          };
          linkConfig.RequiredForOnline = "routable";
        };
      };

      services = {
        "systemd-oomd".serviceConfig.WatchdogSec = 0;
        "systemd-userdbd".serviceConfig.WatchdogSec = 0;
        "systemd-udevd".serviceConfig.WatchdogSec = 0;
        "systemd-timesyncd".serviceConfig.WatchdogSec = 0;
        "systemd-timedated".serviceConfig.WatchdogSec = 0;
        "systemd-portabled".serviceConfig.WatchdogSec = 0;
        "systemd-nspawn@".serviceConfig.WatchdogSec = 0;
        "systemd-machined".serviceConfig.WatchdogSec = 0;
        "systemd-localed".serviceConfig.WatchdogSec = 0;
        "systemd-logind".serviceConfig.WatchdogSec = 0;
        "systemd-journald@".serviceConfig.WatchdogSec = 0;
        "systemd-journald".serviceConfig.WatchdogSec = 0;
        "systemd-journal-remote".serviceConfig.WatchdogSec = 0;
        "systemd-journal-upload".serviceConfig.WatchdogSec = 0;
        "systemd-importd".serviceConfig.WatchdogSec = 0;
        "systemd-hostnamed".serviceConfig.WatchdogSec = 0;
        "systemd-homed".serviceConfig.WatchdogSec = 0;
        "systemd-networkd".serviceConfig.WatchdogSec = lib.mkIf config.systemd.network.enable 0;
      };
    };

    users = {
      # This being `true` leads to a few nasty bugs, change at your own risk!
      mutableUsers = false;

      users.${config.dusk.username} = {
        inherit (config.dusk.folders) home;

        uid = 501;
        extraGroups = [ "wheel" ];

        # simulate isNormalUser, but with an arbitrary UID
        isSystemUser = true;
        isNormalUser = lib.mkForce false;
        group = "users";
        createHome = true;
        homeMode = "700";
        useDefaultShell = true;
      };
    };
  };
}
