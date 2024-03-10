{ pkgs, lib, config, ... }:
with lib; {
  options.dusk.enablePaidApps =
    mkEnableOption "Enable paid apps from the Mac App Store";

  config = {
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
      mas
      ffmpeg
    ];

    homebrew = {
      enable = true;

      masApps = {
        "Amazon Kindle" = 302584613;
        "Amphetamine" = 937984704;
        "Bitwarden Password Manager" = 1352778147;
        "Tailscale" = 1475387142;
        "Telegram" = 747648890;
        "Todoist: To-Do List & Planner" = 585829637;
        "Whatsapp Messenger" = 310633997;
      } // (optionalAttrs config.dusk.enablePaidApps {
        "Monodraw" = 920404675;
      });

      casks = [
        "airtable"
        "dash"
        "discord"
        "element"
        "firefox"
        "iterm2"
        "linearmouse"
        "lm-studio"
        "maccy"
        "mullvadvpn"
        "notion"
        "obs"
        "secretive"
        "session"
        "signal"
        "transmission"
        "visual-studio-code"
        "vlc"
        "orbstack"
      ] ++ (optionals config.dusk.enablePaidApps [ "mountain-duck" ]);

      onActivation = {
        autoUpdate = true;
        upgrade = true;
        cleanup = "uninstall";
      };
    };

    # Make the whole system use the same <nixpkgs> as this flake.
    environment.etc."nix/inputs/nixpkgs".source = "${pkgs.dusk.inputs.nixpkgs}";
    environment.etc."nix/inputs/nix-darwin".source =
      "${pkgs.dusk.inputs.nix-darwin}";

    nix = {
      useDaemon = true;

      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [ "nix-command" "flakes" ];
        system-features = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      };

      # Configure nix to use the flake's nixpkgs
      registry.nixpkgs.flake = pkgs.dusk.inputs.nixpkgs;
      registry.nix-darwin.flake = pkgs.dusk.inputs.nix-darwin;
      nixPath = mkForce [ "/etc/nix/inputs" ];
    };

    programs.bash.enable = true;
    programs.gnupg.agent.enable = true;

    system.stateVersion = 4;
  };
}
