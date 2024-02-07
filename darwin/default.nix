{ pkgs, lib, config, ... }:
with lib; {
  documentation = {
    enable = true;
    doc.enable = true;
    info.enable = true;
    man.enable = true;
  };

  environment.systemPackages = with pkgs; [
    bashInteractive
    curl
    file
    git
    wget
  ];

  homebrew = {
    enable = true;

    masApps = {
      # "Amphetamine" = 37984704;
      # "Bitwarden Password Manager" = 1137397744;
      # "Fantastical Calendar" = 718043190;
      # "Monodraw" = 920404675;
      "Reeder 5" = 1529448980;
      # "Tailscale" = 1470499037;
      "Telegram" = 747648890;
      # "Todoist: To-Do List & Planner" = 572688855;
      "Whatsapp" = 310633997;
    };

    onActivation = {
      autoUpdate = true;
      upgrade = true;
    };
  };

  nix = {
    useDaemon = true;
    gc.automatic = true;

    settings = {
      accept-flake-config = true;
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];

      trusted-substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];
      substituters =
        [ "https://cache.nixos.org" "https://cfcosta-home.cachix.org" ];

      system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    };
  };

  programs.bash.enable = true;
  programs.gnupg.agent.enable = true;

  system.stateVersion = 4;
}
