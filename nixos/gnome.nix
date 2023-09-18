{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.dusk.gnome;
  browsers = with pkgs; [
    (firefox.override { cfg = { enableGnomeExtensions = true; }; })
    brave
    microsoft-edge
  ];

  copyGdmMonitorConfig = pkgs.writeShellScriptBin "gdm-copy-monitor-config" ''
    FILE="/home/${config.dusk.user}/.config/monitors.xml"
    [ -f "$FILE" ] && cp "$FILE" "/run/gdm/.config/monitors.xml"
  '';
in {
  options = { dusk.gnome.enable = mkEnableOption "gnome"; };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        adw-gtk3
        alacritty
        bitwarden
        discord
        element-desktop
        gitg
        meld
        obs-studio
        obsidian
        signal-desktop
        slack
        tdesktop
        todoist-electron
        vial

        # TODO: Find a way to install this only if wayland is not enabled
        xclip
      ] ++ browsers;

    hardware.opengl.enable = true;

    services.xserver = {
      enable = true;

      layout = "us";
      xkbVariant = "";

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };

      desktopManager.gnome.enable = true;

      libinput.enable = true;
    };

    services.avahi = {
      enable = true;

      publish = {
        enable = true;
        userServices = true;
      };

      nssmdns = true;
    };

    services.flatpak.enable = true;
    services.packagekit.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      gnome-photos
      gnome-tour
      gnome.gnome-music
      gnome.gnome-terminal
      gnome.gedit # text editor
      gnome.geary # email reader
      gnome.evince # document viewer
      gnome.gnome-characters
      gnome.totem # video player
      gnome.tali # poker game
      gnome.iagno # go game
      gnome.hitori # sudoku game
      gnome.atomix # puzzle game
    ];

    systemd.services.gdm-set-monitor-config = {
      enable = true;
      description = "Copy the user's monitor config to GDM";

      serviceConfig = {
        ExecStart = "${copyGdmMonitorConfig}/bin/gdm-copy-monitor-config";
        Type = "oneshot";
      };

      before = [ "display-manager.service" ];
    };
  };
}
