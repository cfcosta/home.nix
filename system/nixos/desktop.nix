args@{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.dusk.system.nixos;

  inherit (config.dusk) username;
  inherit (config.dusk.folders) home;
  inherit (import ./firejail args) jail;
  inherit (lib) mkIf;
in
{
  imports = [
    (jail {
      name = "tor-browser";
      executable = "${pkgs.tor-browser}/bin/tor-browser";
      profile = "tor-browser.profile";
      desktop = "${pkgs.tor-browser}/share/applications/torbrowser.desktop";
      graphical = true;
    })
    (jail {
      name = "mullvad-browser";
      executable = "${pkgs.mullvad-browser}/bin/mullvad-browser";
      profile = "google-chrome.profile";
      desktop = "${pkgs.mullvad-browser}/share/applications/mullvad-browser.desktop";
      graphical = true;
    })
  ];

  config = mkIf cfg.desktop.enable {
    environment.systemPackages = with pkgs; [
      anytype
      bitwarden
      brave
      discord
      easyeffects
      element-desktop
      firefox
      fractal
      helvum
      mangohud
      obs-studio
      streamlink-twitch-gui-bin
      tdesktop
      todoist-electron
      wl-clipboard
      zed-editor
    ];

    hardware = {
      graphics.enable = true;
      pulseaudio.enable = false;
    };

    nix.settings = {
      substituters = [ "https://cosmic.cachix.org/" ];

      trusted-public-keys = [
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
      ];
    };

    programs = {
      firejail.enable = true;
      gnupg.agent.pinentryPackage = pkgs.pinentry-gnome3;
      steam.enable = true;
    };

    security.rtkit.enable = true;

    services = {
      avahi = {
        enable = true;

        publish = {
          enable = true;
          userServices = true;
        };

        nssmdns4 = true;
      };

      desktopManager.cosmic.enable = true;
      flatpak.enable = true;
      libinput.enable = true;
      packagekit.enable = true;

      pipewire = {
        enable = true;

        pulse.enable = true;
        jack.enable = true;
      };

      syncthing = {
        enable = true;

        user = username;
        dataDir = "${home}/Sync";
      };

      xserver = {
        enable = true;

        displayManager.gdm = {
          enable = true;
          autoSuspend = false;
          wayland = true;
        };
      };
    };
  };
}
