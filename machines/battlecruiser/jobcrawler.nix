{ config, ... }: {
  # Run the jobcrawler daemon (~/Code/cfcosta/jobcrawler: crawl fleet,
  # LLM match scoring, web UI on :8765) as a managed user service, same
  # always-on pattern as homelab-vm.nix (linger brings it up at boot).
  #
  # `nix develop -c` is load-bearing: the daemon needs the repo flake's dev
  # shell (editable install; bare .venv python lacks libstdc++ for
  # tokenizers on NixOS), and since the install is editable each restart
  # picks up the working copy — edit, then
  # `systemctl --user restart jobcrawler`. Logs land in the journal
  # (`journalctl --user -u jobcrawler -f`).
  config.home-manager.users.${config.dusk.username}.systemd.user.services.jobcrawler = {
    Unit.Description = "jobcrawler daemon (crawl + match scoring + web UI on :8765)";

    Service = {
      # The live SQLite DB (jobcrawler.db) is resolved relative to the
      # daemon's cwd, so the working directory must be the repo root.
      WorkingDirectory = "${config.dusk.folders.code}/cfcosta/jobcrawler";

      # PATH carries git for nix's local-flake evaluation (same reason as
      # homelab-vm). PYTHONUNBUFFERED because the generation pipeline's
      # diagnostics are print()s — block-buffered through pipes, they'd be
      # invisible in the journal and lost on a kill.
      Environment = [
        "PATH=/run/current-system/sw/bin"
        "PYTHONUNBUFFERED=1"
      ];

      # Model choice, rate/concurrency/cap knobs and the API keys live in
      # a mode-600 file OUTSIDE the store and the repo (secrets). Systemd
      # reads plain KEY=value lines — no `export`/`set -a` needed (that
      # shell subtlety once left the daemon silently running on default
      # model and cap). Retune by editing the file and restarting the
      # unit; no rebuild.
      EnvironmentFile = "%h/.config/jobcrawler/daemon.env";

      ExecStart = "/run/current-system/sw/bin/sh -c 'exec nix develop -c python -m jobcrawler.cli run --host 0.0.0.0'";

      # The daemon should simply always be up; RestartSec gives a crashed
      # LLM backend or a half-written working copy a moment to settle.
      Restart = "always";
      RestartSec = 15;

      # SIGTERM is held until the current scheduler tick finishes, and a
      # generation-heavy tick can hold it for many minutes — don't wait it
      # out on stop/restart. SIGKILL after 30s is safe: the store is
      # SQLite in WAL mode and every in-flight LLM grant was reserved up
      # front, so a hard kill loses nothing but the interrupted pass.
      TimeoutStopSec = 30;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
