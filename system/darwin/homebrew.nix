{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      mas
      streamlink
    ];

    homebrew = {
      enable = true;

      brews = [ "nss" ];
      casks = [
        "betaflight-configurator"
        "bitwarden"
        "brave-browser"
        "chatgpt"
        "discord"
        "handbrake-app"
        "inkscape"
        "linearmouse"
        "mountain-duck"
        "mullvad-vpn"
        "obs"
        "obsidian"
        "orbstack"
        "secretive"
        "steam"
        "streamlink-twitch-gui"
        "syncthing-app"
        "tailscale-app"
        "telegram"
        "todoist-app"
        "vlc"
        "whatsapp"
      ];

      caskArgs.no_quarantine = true;

      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "uninstall";
      };
    };
  };
}
