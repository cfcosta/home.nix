{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.gnome;
in {
  options = {
    devos.gnome.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable the gnome desktop environment
      '';
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;

      layout = "us";
      xkbVariant = "";

      displayManager.gdm = {
        enable = true;
        wayland = true;
      };
      desktopManager.gnome.enable = true;

      libinput.enable = true;
    };

    environment.systemPackages = with pkgs; [
      alacritty
      bitwarden
      bloomrpc
      brave
      cawbird
      chromium
      discord
      element-desktop
      firefox
      gimp
      gnome.polari
      gnomeExtensions.gsconnect
      gnomeExtensions.freon
      inkscape
      krita
      obs-studio
      obsidian
      rnote
      spot
      tdesktop
      thunderbird
      todoist-electron
    ];

    hardware.opengl.enable = true;

    services.avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
      nssmdns = true;
    };

    services.flatpak.enable = true;
    services.packagekit.enable = true;
  };
}
