{ ... }:
{
  dusk.home = {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    git.enable = true;
    media.enable = true;
    zed.enable = true;

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
