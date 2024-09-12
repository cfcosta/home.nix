_: {
  config = {
    homebrew = {
      enable = true;

      casks = [ "raycast" ];
    };

    system.defaults.CustomUserPreferences."com.raycast.macos" = {
      initialSpotlightHotkey = "Command-49";
      raycastGlobalHotkey = "Command-49";
      onboardingCompleted = 1;
      developerFlags = 0;
    };
  };
}
