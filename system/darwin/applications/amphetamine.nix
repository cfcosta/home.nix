# Amphetamine: keep your Mac display awake.
# https://apps.apple.com/us/app/amphetamine/id937984704
_: {
  homebrew = {
    enable = true;
    casks = [ "amphetamine" ];
  };

  system.defaults.CustomUserPreferences."com.if.Amphetamine" = {
    SUAutomaticallyUpdate = 0;
    SUEnableAutomaticChecks = 0;
    SUHasLaunchedBefore = 1;

    "Show Welcome Window" = 0;
    "Start Session At Launch" = 1;
    "Start Session On Wake" = 1;
  };
}
