{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.dusk.cosmic;
in
{
  options = {
    dusk.cosmic.enable = mkEnableOption "cosmic-desktop";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bitwarden
      brave
      discord
      easyeffects
      element-desktop
      firefox
      fractal
      gamescope
      helvum
      mangohud
      obs-studio
      tdesktop
      todoist-electron
      xclip
      zed-editor
    ];

    hardware.graphics.enable = true;
    hardware.pulseaudio.enable = false;

    programs.steam.enable = true;

    security.rtkit.enable = true;

    services.desktopManager.cosmic.enable = true;

    services.xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
        wayland = true;
      };
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

    services.syncthing = {
      enable = true;
      user = config.dusk.user;
      dataDir = "/home/${config.dusk.user}";
    };

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
