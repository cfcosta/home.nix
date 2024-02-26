{ pkgs, lib, config, ... }:
with lib; {
  options.dusk.enablePaidApps =
    mkEnableOption "Enable paid apps from the Mac App Store";

  config = {
    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    environment.systemPackages = with pkgs; [
      bashInteractive
      curl
      file
      git
      wget
      mas
    ];

    homebrew = {
      enable = true;

      masApps = {
        "Amazon Kindle" = 302584613;
        "Amphetamine" = 937984704;
        "Bitwarden Password Manager" = 1352778147;
        "Fantastical Calendar" = 975937182;
        "Reeder 5" = 1529448980;
        "Tailscale" = 1475387142;
        "Telegram" = 747648890;
        "Todoist: To-Do List & Planner" = 585829637;
        "Whatsapp Messenger" = 310633997;
      } // (optionalAttrs config.dusk.enablePaidApps {
        "Monodraw" = 920404675;
      });

      casks = [
        "dash"
        "discord"
        "element"
        "firefox"
        "iterm2"
        "linearmouse"
        "lm-studio"
        "mullvadvpn"
        "notion"
        "obs"
        "secretive"
        "session"
        "signal"
        "transmission"
        "visual-studio-code"
        "vlc"
      ] ++ (optionals config.dusk.enablePaidApps [ "mountain-duck" ]);

      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "uninstall";
      };
    };

    nix = {
      useDaemon = true;
      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      };
    };

    programs.bash.enable = true;
    programs.gnupg.agent.enable = true;

    system.stateVersion = 4;
  };
}
