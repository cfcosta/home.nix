# Swish - Better window management when using trackpads
# https://highlyopinionated.co/swish/
_: {
  homebrew = {
    enable = true;
    casks = [ "swish" ];
  };

  system.defaults.CustomUserPreferences."co.highlyopinionated.swish" = {
    showInMenubar = 0;
  };
}
