{ pkgs, lib, ... }:
let
  inherit (lib) mkForce;
  inherit (pkgs) writeShellScriptBin;

  ollamaAlias = writeShellScriptBin "ollama" ''
    exec /opt/homebrew/bin/ollama "$@"
  '';
in
{
  imports = [
    ./clipboard.nix
    ./raycast.nix
  ];

  config = {
    documentation = {
      enable = true;
      doc.enable = true;
      info.enable = true;
      man.enable = true;
    };

    system = {
      keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };

      defaults.CustomUserPreferences = {
        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;

          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };

        # Disable UI sounds
        "com.apple.sound.uiaudio".enabled = false;

        defaults = {
          NSGlobalDomain = {
            # Force dark mode globally
            AppleInterfaceStyle = "Dark";
            AppleInterfaceStyleSwitchesAutomatically = false;

            # Disable automatic capitalization as it’s annoying when typing code
            NSAutomaticCapitalizationEnabled = false;

            # Disable smart dashes as they’re annoying when typing code
            NSAutomaticDashSubstitutionEnabled = false;

            # Disable automatic period substitution as it’s annoying when typing code
            NSAutomaticPeriodSubstitutionEnabled = false;

            # Disable smart quotes as they’re annoying when typing code
            NSAutomaticQuoteSubstitutionEnabled = false;

            # Disable auto-correct
            NSAutomaticSpellingCorrectionEnabled = false;

            # Enable full keyboard access for all controls
            # (e.g. enable Tab in modal dialogs)
            AppleKeyboardUIMode = 3;

            # Disable press-and-hold for keys in favor of key repeat
            ApplePressAndHoldEnabled = false;

            # Set a blazingly fast keyboard repeat rate
            KeyRepeat = 1;
            InitialKeyRepeat = 30;

            # Enable subpixel font rendering on non-Apple LCDs
            # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
            AppleFontSmoothing = 1;

            # Finder: show all filename extensions
            AppleShowAllExtensions = true;
          };
        };
      };
    };

    environment.systemPackages = [
      ollamaAlias
      pkgs.bashInteractive
      pkgs.curl
      pkgs.file
      pkgs.git
      pkgs.mas
      pkgs.wget
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

      taps = [ "LouisBrunner/valgrind" ];

      casks = [
        "LouisBrunner/valgrind/valgrind"

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
        "swish"
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

    # Make the whole system use the same <nixpkgs> as this flake.
    environment.etc."nix/inputs/nixpkgs".source = "${pkgs.dusk.inputs.nixpkgs}";
    environment.etc."nix/inputs/nix-darwin".source = "${pkgs.dusk.inputs.nix-darwin}";

    nix = {
      useDaemon = true;

      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      };

      # Configure nix to use the flake's nixpkgs
      registry.nixpkgs.flake = pkgs.dusk.inputs.nixpkgs;
      registry.nix-darwin.flake = pkgs.dusk.inputs.nix-darwin;
      nixPath = mkForce [ "/etc/nix/inputs" ];
    };

    programs.bash.enable = true;
    programs.gnupg.agent.enable = true;

    system.stateVersion = 4;
  };
}
