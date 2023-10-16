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
        guvcview
        heaptrack
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
      gnome.atomix # puzzle game
      gnome.evince # document viewer
      gnome.geary # email reader
      gnome.gedit # text editor
      gnome.gnome-characters # character map
      gnome.gnome-music # music player
      gnome.gnome-software # software center
      gnome.gnome-terminal
      gnome.hitori # sudoku game
      gnome.iagno # go game
      gnome.tali # poker game
      gnome.totem # video player
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
