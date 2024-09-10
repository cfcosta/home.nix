{ pkgs, ... }:
{
  imports = [
    ./clipboard.nix
    ./raycast.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      mas
    ];

    homebrew = {
      enable = true;

      masApps = {
        "Amazon Kindle" = 302584613;
        "Amphetamine" = 937984704;
        "Bitwarden Password Manager" = 1352778147;
        "Tailscale" = 1475387142;
        "Telegram" = 747648890;
        "Todoist: To-Do List & Planner" = 585829637;
        "Whatsapp Messenger" = 310633997;
      };

      casks = [
        "brave-browser"
        "chromedriver"
        "cursor"
        "discord"
        "element"
        "firefox"
        "gitify"
        "google-chrome"
        "inkscape"
        "iterm2"
        "linearmouse"
        "mountain-duck"
        "mullvadvpn"
        "obs"
        "ollama"
        "orbstack"
        "secretive"
        "signal"
        "streamlink-twitch-gui"
        "swish"
        "syncthing"
        "tor-browser"
        "transmission"
        "vlc"
        "xmind"
        "zed"
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
