# Orion Browser
_: {
  homebrew = {
    enable = true;
    casks = [ "orion" ];
  };

  system.defaults.CustomUserPreferences."com.apple.LaunchServices" = {
    LSHandlers = [
      {
        LSHandlerURLScheme = "http";
        LSHandlerRoleAll = "com.orionbrowser.orion"; # replace with Orion’s actual bundle identifier
      }
      {
        LSHandlerURLScheme = "https";
        LSHandlerRoleAll = "com.orionbrowser.orion";
      }
    ];
  };
}
