{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkOption
    types
    ;
  inherit (pkgs.stdenv) isLinux;

  mkEnabledNixosOption =
    args:
    mkOption (
      {
        type = types.bool;
        default = isLinux;
      }
      // args
    );
in
{
  options.dusk = {
    initialPassword = mkOption {
      type = types.str;
      description = "Initial password for the created user in the system ";
      default = "dusk";
    };

    accounts.github = mkOption { type = types.str; };
    email = mkOption { type = types.str; };
    name = mkOption { type = types.str; };
    username = mkOption {
      type = types.str;
      description = "User name of the main user of the system ";
    };

    folders =
      let
        home = if isLinux then "/home/${config.dusk.username}" else "/Users/${config.dusk.username}";
      in
      {
        code = mkOption {
          type = types.str;
          description = "Where you host your working projects";
          default = "${home}/Code";
        };

        downloads = mkOption {
          type = types.str;
          description = "Where you host your Downloads";
          default = "${home}/Downloads";
        };

        home = mkOption {
          type = types.str;
          description = "Your home folder";
          default = home;
        };
      };

    alacritty = {
      font = {
        family = mkOption {
          type = types.str;
          default = "Inconsolata NerdFont Mono";
        };

        size = mkOption {
          type = types.float;
          default = 14.0;
        };
      };
    };

    git = {
      signByDefault =
        mkEnabledNixosOption
          {
          };

      defaultBranch = mkOption {
        type = types.str;
        default = "main";
      };
    };

    system = {
      hostname = mkOption {
        type = types.str;
        description = "The hostname of the system on the network";
        default = "dusk";
      };

      locale = mkOption {
        type = types.str;
        default = "en_US.utf8";
        description = "Locale of the system ";
      };

      timezone = mkOption {
        type = types.str;
        default = "America/Sao_Paulo";
        description = "Timezone to use for the system";
      };

      nixos = {
        createUser = mkEnabledNixosOption {
          description = "Whether or not to create the main user";
        };

        bootloader.enable = mkEnabledNixosOption {
          description = "Whether or not to install a bootloader";
        };

        nvidia.enable = mkEnabledNixosOption {
          description = "Whether or not to enable support for Nvidia Cards";
        };

        desktop.enable = mkEnabledNixosOption {
          description = "Whether or not to enable the Graphical Desktop";
        };

        networking.enable = mkEnabledNixosOption {
          description = "Whether or not to enable NetworkManager";
        };

        virtualisation = {
          enable = mkEnabledNixosOption {
            description = "Whether or not to enable Virtualisation Tooling";
          };

          docker.enable = mkEnabledNixosOption {
            description = "Whether or not to enable Docker";
          };

          libvirt.enable = mkEnabledNixosOption {
            description = "Whether or not to enable LibVirt";
          };

          podman.enable = mkEnabledNixosOption {
            description = "Whether or not to enable Podman";
          };

          waydroid.enable = mkEnabledNixosOption {
            description = "Whether or not to enable Waydroid (run android apps on Linux)";
          };
        };
      };
    };

    tmux.showBattery = lib.mkEnableOption "tmux show battery level";
  };
}
