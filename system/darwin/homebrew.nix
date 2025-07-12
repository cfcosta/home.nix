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
        "element"
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
