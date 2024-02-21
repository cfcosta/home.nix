{ pkgs, ... }:
let inherit (pkgs.lib) mkEnableOption mkOption types;
in {
  options.dusk = rec {
    enable = mkEnableOption "dusk-core";

    system = {
      locale = mkOption {
        type = types.str;
        default = "en_US.utf8";
        description = ''
          Locale of the system
        '';
      };
    };

    user = {
      name = mkOption { type = types.str; };
      email = mkOption { type = types.str; };

      username = mkOption { type = types.str; };
      initialPassword = mkOption {
        type = types.str;
        description = ''
          Initial password for the created user in the system
        '';
        default = "dusk";
      };

      accounts.github = mkOption { type = types.str; };

      folders = {
        code = mkOption {
          type = types.str;
          default = "${folders.home}/Code";
          description = "Where you host your working projects";
        };

        home = mkOption {
          type = types.str;
          default = if pkgs.stdenv.isLinux then
            "/home/${user.username}"
          else
            "/Users/${user.username}";
          description = "Your home folder";
        };
      };
    };

    alacritty = {
      enable = mkEnableOption "alacritty";

      theme = mkOption {
        type = types.str;
        default = "moonlight_ii_vscode";
        description = "The theme to use for alacritty";
      };

      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata";
        };

        size = mkOption {
          type = types.float;
          default = 14.0;
        };
      };
    };

    android.enable = mkEnableOption "ADB and other android tools";
    virtualbox.enable = mkEnableOption "virtualbox";
    tailscale.enable = mkEnableOption "tailscale";
    sound.enable = mkEnableOption "sound";
    libvirt.enable = mkEnableOption "libvirt";
    icognito.enable = mkEnableOption "icognito";
    gaming.enable = mkEnableOption "gaming";
    containers.enable = mkEnableOption "containers";
    benchmarking.enable =
      mkEnableOption "Benchmarking and stress testing tools";
    amd.enable = mkEnableOption "AMD Config and Optimizations";
    media.enable = mkEnableOption "media";

    tmux = {
      enable = mkEnableOption "tmux";
      showBattery = mkEnableOption "tmux show battery level";
    };

    darwin = { enablePaidApps = true; };

    git = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };

      signByDefault = mkOption {
        type = types.bool;
        default = true;
      };

      defaultBranch = mkOption {
        type = types.str;
        default = "main";
      };
    };

    gnome = {
      enable = mkEnableOption "gnome";
      darkTheme = mkEnableOption "gnome-dark-theme";

      keymaps = mkOption {
        type = types.listOf types.str;
        default = [ "us" ];
      };

      numberOfWorkspaces = mkOption {
        type = types.int;
        default = 6;
      };

      defaults.browser = mkOption {
        type = types.enum [ "firefox" "brave" ];
        default = "firefox";
      };
    };

    macos.enable = mkOption {
      default = pkgs.stdenv.isDarwin;
      example = true;
      description = "Whether to enable MacOS extensions.";
      type = types.bool;
    };

    shell = {
      environmentFile = mkOption {
        type = types.str;
        default = "${user.folders.home}/dusk-env.sh";
        description = ''
          A bash file that is loaded by the shell on each run.
          This is used to set secrets or credentials that we don't want on the repo.
        '';
      };
    };

    nvidia = {
      enable = mkEnableOption "Support for NVIDIA GPUs";
      powerLimit = mkOption {
        type = types.int or types.null;
        description = "Power limit in watts, disabled if null.";
      };
    };
  };
}
