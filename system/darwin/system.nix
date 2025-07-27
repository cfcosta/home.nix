{ config, ... }:
{
  config.system = {
    primaryUser = config.dusk.username;

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };

    defaults = {
      controlcenter = {
        # Hide icons from the menubar
        AirDrop = false;
        Bluetooth = true;
        Display = false;
        FocusModes = false;
        NowPlaying = false;
        Sound = false;

        BatteryShowPercentage = true;
      };

      menuExtraClock = {
        Show24Hour = true;
        ShowSeconds = true;
      };

      CustomUserPreferences = {
        "com.apple.AdLib" = {
          allowApplePersonalizedAdvertising = false;
          allowIdentifierForAdvertising = false;
          forceLimitAdTracking = true;
          personalizedAdsMigrated = false;
        };

        "com.apple.desktopservices" = {
          # Avoid creating .DS_Store files on network or USB volumes
          DSDontWriteNetworkStores = true;
          DSDontWriteUSBStores = true;
        };

        "com.apple.SoftwareUpdate" = {
          AutomaticCheckEnabled = true;
          AutomaticallyInstallMacOSUpdates = true;

          # Check for software updates daily, not just once per week
          ScheduleFrequency = 1;
          # Download newly available updates in background
          AutomaticDownload = 1;
          # Install System data files & security updates
          CriticalUpdateInstall = 1;
        };

        # Disable UI sounds
        "com.apple.sound.uiaudio".enabled = false;

        # Displays have separate spaces
        "com.apple.spaces"."spans-displays" = 0;

        "com.apple.WindowManager" = {
          EnableStandardClickToShowDesktop = 0; # Click wallpaper to reveal desktop
          StandardHideDesktopIcons = 0; # Show items on desktop
          HideDesktop = 0; # Do not hide items on desktop & stage manager
          StageManagerHideWidgets = 0;
          StandardHideWidgets = 0;
        };

        "dev.kdrag0n.MacVirt" = {
          SUHasLaunchedBefore = 1;
          SUAutomaticallyUpdate = 0;
        };
      };

      finder = {
        # Finder: show all filename extensions
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;

        # Show the full POSIX path as Finder's window title
        _FXShowPosixPathInTitle = true;
      };

      NSGlobalDomain = {
        # Set Locale
        AppleMeasurementUnits = "Centimeters";
        AppleMetricUnits = 1;
        AppleTemperatureUnit = "Celsius";

        # Hide scrollbars
        AppleShowScrollBars = "WhenScrolling";

        # disable automatic typography options
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;

        # always expand the print panel
        PMPrintingExpandedStateForPrint = true;
        PMPrintingExpandedStateForPrint2 = true;

        # Expand the save panel by default
        NSNavPanelExpandedStateForSaveMode = true;
        NSNavPanelExpandedStateForSaveMode2 = true;

        # Do not save stuff to iCloud
        NSDocumentSaveNewDocumentsToCloud = false;

        # Force dark mode globally
        AppleInterfaceStyle = "Dark";
        AppleInterfaceStyleSwitchesAutomatically = false;

        # Enable full keyboard access for all controls
        # (e.g. enable Tab in modal dialogs)
        AppleKeyboardUIMode = 3;

        # Disable press-and-hold for keys in favor of key repeat
        ApplePressAndHoldEnabled = false;

        # Set faster keyboard repeat rate
        KeyRepeat = 1;
        InitialKeyRepeat = 30;

        # Enable subpixel font rendering on non-Apple LCDs
        # Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
        AppleFontSmoothing = 1;
      };
    };

    stateVersion = 5;
  };
}
