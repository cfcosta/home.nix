{ ... }: {
  dusk = {
    enable = true;

    user = {
      name = "Cainã Costa";
      username = "cfcosta";
      email = "me@cfcosta.com";
      accounts.github = "cfcosta";
    };

    system = {
      hostname = "battlecruiser";
      tz = "America/Sao_Paulo";
    };

    alacritty.enable = true;
    amd.enable = true;
    android.enable = true;
    benchmarking.enable = true;
    containers.enable = true;
    gaming.enable = true;
    git.enable = true;
    icognito.enable = true;
    libvirt.enable = true;
    media.enable = true;
    sound.enable = true;
    tailscale.enable = true;
    tmux.enable = true;

    gnome = {
      enable = true;
      darkTheme = true;
      keymaps = [ "us" "us+intl" ];
    };

    nvidia = {
      enable = true;
      powerLimit = 150;
    };
  };
}
