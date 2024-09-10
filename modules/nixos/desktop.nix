{
  pkgs,
  lib,
  config,
  ...
}:
lib.optionalAttrs config.dusk.cosmic.enable {
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
      inherit (config.dusk) username;
      dataDir = "/home/${config.dusk.username}";
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

}
