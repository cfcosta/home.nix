_: {
  config.system = {
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

    stateVersion = 5;
  };
}
