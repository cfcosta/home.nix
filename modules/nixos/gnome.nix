{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
  cfg = config.dusk.gnome;

  copyGdmMonitorConfig = pkgs.writeShellScriptBin "gdm-copy-monitor-config" ''
    FILE="/home/${config.dusk.user}/.config/monitors.xml"
    [ -f "$FILE" ] && cp "$FILE" "/run/gdm/.config/monitors.xml"
  '';
in
{
  options = {
    dusk.gnome.enable = mkEnableOption "gnome";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      (with pkgs; [
        adw-gtk3
        bitwarden
        brave
        discord
        element-desktop
        firefox
        fractal
        obs-studio
        tdesktop
        todoist-electron
        xclip
        zed-editor

        gnomeExtensions.forge
      ])
      ++ optionals (!config.services.xserver.displayManager.gdm.wayland) [ pkgs.xclip ];

    hardware.graphics.enable = true;

    services.xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "";
      };

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };

      desktopManager.gnome.enable = true;
    };

    services.libinput.enable = true;

    services.avahi = {
      enable = true;

      publish = {
        enable = true;
        userServices = true;
      };

      nssmdns4 = true;
    };

    services.flatpak.enable = true;
    services.packagekit.enable = true;

    services.gnome.gnome-browser-connector.enable = true;

    environment.gnome.excludePackages = with pkgs; [
      gnome-console
      gnome-photos
      gnome-tour
      geary
      totem

      gnome.atomix
      gnome.gnome-characters
      gnome.gnome-music
      gnome.gnome-software
      gnome.hitori
      gnome.iagno
      gnome.tali
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

    services.syncthing = {
      enable = true;
      user = config.dusk.user;
      dataDir = "/home/${config.dusk.user}";
    };
  };
}
