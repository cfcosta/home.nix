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
        "bitwarden"
        "brave-browser"
        "chatgpt"
        "discord"
        "element"
        "firefox"
        "gitify"
        "inkscape"
        "iterm2"
        "linearmouse"
        "moonlight"
        "mountain-duck"
        "mullvadvpn"
        "obs"
        "obsidian"
        "ollama"
        "orbstack"
        "secretive"
        "simplex"
        "streamlink-twitch-gui"
        "syncthing"
        "tailscale"
        "telegram"
        "todoist"
        "tor-browser"
        "vlc"
        "whatsapp"
        "zed"
        "zen-browser"
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
