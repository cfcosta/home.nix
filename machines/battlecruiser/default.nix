{ config, ... }: {
  imports = [
    ./desktop.nix
    ./hardware.nix
    ./homelab-vm.nix
    ./jobcrawler.nix
    ./keyboard.nix
    ./monitors.nix
    ./networking.nix
    ./romm-save-sync.nix
  ];

  config = {
    dusk = {
      fonts.monospace = "Berkeley Mono NerdFont Mono";

      terminal.font-size = 12;

      shell.starship.disabledModules = [
        "cmd_duration"
        "dart"
        "fossil_branch"
        "fossil_metrics"
        "git_branch"
        "git_commit"
        "git_metrics"
        "git_state"
        "git_status"
        "gradle"
        "guix_shell"
        "hg_branch"
        "java"
        "package"
        "package"
        "pijul_channel"
        "vagrant"
      ];

      system.hostname = "battlecruiser";
    };

    # Keep this user's systemd instance running at boot and across logouts, so
    # the homelab-vm, jobcrawler and romm-save-sync units (user services, in
    # the sibling files of the same name) are genuinely always-on rather than
    # tied to a graphical login — without lingering, user units start at first
    # login and are torn down when the last session ends. Linger was already on
    # here (set by hand via `loginctl enable-linger`); declaring it makes that
    # reproducible and self-healing on activation.
    users.users.${config.dusk.username}.linger = true;
  };
}
