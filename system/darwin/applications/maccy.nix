# Maccy, a clipboard manager
# https://maccy.app/
_: {
  homebrew = {
    enable = true;
    casks = [ "maccy" ];
  };

  system.defaults.CustomUserPreferences."org.p0deje.Maccy" = {
    SUAutomaticallyUpdate = 0;
    SUEnableAutomaticChecks = 0;
    SUHasLaunchedBefore = 1;

    searchMode = "fuzzy";
    previewDelay = 150;
    maxMenuItemLength = 25;
    menuIcon = "clipboard";
  };
}
