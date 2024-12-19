# Raycast - A better replacement for Spotlight
# https://www.raycast.com/
_: {
  config = {
    homebrew = {
      enable = true;
      casks = [ "raycast" ];
    };

    system.defaults.CustomUserPreferences."com.raycast.macos" = {
      SUAutomaticallyUpdate = 0;
      SUEnableAutomaticChecks = 0;
      SUHasLaunchedBefore = 1;

      initialSpotlightHotkey = "Command-49";
      raycastGlobalHotkey = "Command-49";
      onboardingCompleted = 1;
      developerFlags = 0;
    };
  };
}
