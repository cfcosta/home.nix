{ config, lib, pkgs, ... }: {
  dusk.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    alacritty.enable = true;
    android.enable = true;
    git.enable = true;
    macos.enable = true;
    media.enable = true;
    mutt.enable = true;
    notes.enable = true;

    tmux = {
      enable = true;
      showBattery = true;
    };
  };

  programs.bash.profileExtra = ''
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
  '';
}
