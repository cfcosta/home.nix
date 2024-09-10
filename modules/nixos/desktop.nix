{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.dusk.cosmic.enable = mkEnableOption "cosmic";

  config = mkIf config.dusk.cosmic.enable {
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
      simplex-chat-desktop
      streamlink-twitch-gui-bin
      tartube-yt-dlp
      tdesktop
      todoist-electron
      xclip
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

    programs.steam.enable = true;

    security.rtkit.enable = true;

    services.avahi = {
      enable = true;

      publish = {
        enable = true;
        userServices = true;
      };

      nssmdns4 = true;
    };

    services.desktopManager.cosmic.enable = true;
    services.flatpak.enable = true;
    services.libinput.enable = true;
    services.packagekit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    services.syncthing = {
      enable = true;
      inherit (config.dusk) user;
      dataDir = "/home/${config.dusk.user}";
    };

    services.xserver = {
      enable = true;
      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
        wayland = true;
      };
    };
  };
}
