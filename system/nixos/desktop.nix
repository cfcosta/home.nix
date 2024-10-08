{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dusk.system.nixos.desktop;

  inherit (config.dusk) username;
  inherit (config.dusk.folders) home;
  inherit (lib) mkIf optionals;
in
{
  imports = [ ./cosmic ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        # Enable Wayland support on most Electron applications
        NIXOS_OZONE_WL = "1";

        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
      };

      systemPackages =
        with pkgs;
        [
          anytype
          astroid
          bitwarden
          brave
          chromedriver
          discord
          easyeffects
          element-desktop
          feishin
          firefox
          fractal
          gamemode
          google-chrome
          gossip
          helvum
          inkscape
          mangohud
          moonlight-qt
          mullvad-browser
          obs-studio
          obsidian
          pinta
          simplex-chat-desktop
          streamlink-twitch-gui-bin
          tdesktop
          todoist-electron
          tor-browser
          vlc
          wireshark
          wl-clipboard-rs
          xournalpp
          zed-editor

          # Fonts
          cantarell-fonts
          dejavu_fonts
          source-code-pro
          source-sans
        ]
        ++ optionals cfg.alacritty.enable [ alacritty ]
        ++ optionals config.dusk.system.nixos.virtualisation.libvirt.enable [ virt-manager ];
    };

    hardware = {
      graphics.enable = true;
      pulseaudio.enable = false;

      # Support for Xbox One Controllers
      xone.enable = true;
    };

    programs = {
      gamescope = {
        enable = true;
        capSysNice = true;
      };

      gnupg.agent.pinentryPackage = pkgs.pinentry-all;

      steam = {
        enable = true;

        dedicatedServer.openFirewall = true;
        gamescopeSession.enable = true;
        localNetworkGameTransfers.openFirewall = true;
        remotePlay.openFirewall = true;
      };
    };

    security.rtkit.enable = true;

    services = {
      sunshine = {
        enable = true;
        autoStart = true;
        capSysAdmin = true;
        openFirewall = true;
      };

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
    };

    users.users.${config.dusk.username}.extraGroups = [ "gamemode" ];
  };
}
