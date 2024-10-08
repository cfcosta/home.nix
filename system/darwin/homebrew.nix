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
        "chromedriver"
        "cool-retro-term"
        "discord"
        "element"
        "firefox"
        "gitify"
        "google-chrome"
        "inkscape"
        "iterm2"
        "linearmouse"
        "mitmproxy"
        "moonlight"
        "mountain-duck"
        "mullvadvpn"
        "obs"
        "obsidian"
        "ollama"
        "orbstack"
        "secretive"
        "signal"
        "simplex"
        "streamlink-twitch-gui"
        "swish"
        "syncthing"
        "tor-browser"
        "vlc"
        "wireshark"
        "zed"
        "zen-browser"
      ];

      caskArgs.no_quarantine = true;

      masApps = {
        "Amazon Kindle" = 302584613;
        "Amphetamine" = 937984704;
        "Tailscale" = 1475387142;
        "Telegram" = 747648890;
        "Todoist: To-Do List & Planner" = 585829637;
        "Whatsapp Messenger" = 310633997;
      };

      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "uninstall";
      };
    };
  };
}
