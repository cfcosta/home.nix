_: {
  homebrew = {
    enable = true;
    casks = [ "maccy" ];
  };

  system.defaults.CustomUserPreferences."org.p0deje.Maccy" = {
    SUAutomaticallyUpdate = 1;
    SUEnableAutomaticChecks = 1;
    SUHasLaunchedBefore = 1;
    searchMode = "fuzzy";
    previewDelay = 300;
    maxMenuItemLength = 75;
    menuIcon = "clipboard";
  };
}
