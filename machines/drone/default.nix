{ ... }: {
  dusk = {
    user = {
      name = "Cainã Costa";
      username = "cfcosta";
      email = "me@cfcosta.com";
      accounts.github = "cfcosta";
    };

    git.enable = true;
    macos.enable = true;
    media.enable = true;

    darwin.enablePaidApps = true;

    tmux = {
      enable = true;
      showBattery = true;
    };
  };
}
