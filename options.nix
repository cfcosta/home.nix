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
    {
      description ? "Enable unnamed NixOS module",
      parent ? null,
    }:
    mkOption {
      inherit description;

      type = types.bool;
      default = if parent == null then isLinux else parent;
    };
in
{
  options.dusk = {
    initialPassword = mkOption {
      type = types.str;
      description = "Initial password for the created user in the system ";
      default = "dusk";
    };

    accounts.github = mkOption {
      type = types.str;
      description = "The user Github Account";
    };

    emails = {
      primary = mkOption {
        type = types.str;
        description = "The primary email used by the user";
      };

      additional = mkOption {
        type = types.listOf types.str;
        description = "Additional email addresses for the user";
        default = [ ];
      };
    };

    name = mkOption {
      type = types.str;
      description = "The full name of the user";
    };

    username = mkOption {
      type = types.str;
      description = "User name of the main user of the system ";
    };

    defaults = {
      browser = mkOption {
        type = types.str;
        description = "Your default browser";
        default = "firefox";
      };

      terminal = mkOption {
        type = types.str;
        description = "Your default terminal emulator";
        default = if config.dusk.system.desktop.alacritty.enable then "alacritty" else "cosmic-term";
      };
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

        mail = mkOption {
          type = types.str;
          description = "Your root mail folder";
          default = "${home}/Mail";
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

      git = {
        signByDefault = mkOption {
          type = types.bool;
          default = true;
          description = "Whether or not git should sign all commits";
        };

        defaultBranch = mkOption {
          type = types.str;
          default = "main";
          description = "The default branch to use for new git repositories";
        };
      };

      nixos =
        let
          cfg = config.dusk.system.nixos;
        in
        {
          createUser = mkEnabledNixosOption {
            description = "Whether or not to create the main user";
          };

          bootloader.enable = mkEnabledNixosOption {
            description = "Whether or not to install a bootloader";
          };

          nvidia.enable = mkEnabledNixosOption {
            description = "Whether or not to enable support for Nvidia Cards";
          };

          desktop = {
            enable = mkEnabledNixosOption {
              description = "Whether or not to enable the Graphical Desktop";
            };

            alacritty = {
              enable = mkEnabledNixosOption {
                description = "Whether or not to enable the Alacritty Terminal";
                parent = config.desktop.enable;
              };

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
          };

          networking = {
            enable = mkEnabledNixosOption {
              description = "Whether or not to enable NetworkManager";
            };

            defaultNetworkInterface = mkOption {
              type = types.str;
              default = "eno1";
              description = "The name of the main network interface for the host";
            };

            i2p.enable = mkEnabledNixosOption {
              description = "Whether or not to enable i2p";
              parent = cfg.networking.enable;
            };

            mullvad.enable = mkEnabledNixosOption {
              description = "Whether or not to enable Mullvad VPN";
              parent = cfg.networking.enable;
            };

            tailscale.enable = mkEnabledNixosOption {
              description = "Whether or not to enable Tailscale VPN";
              parent = cfg.networking.enable;
            };
          };

          virtualisation = {
            enable = mkEnabledNixosOption {
              description = "Whether or not to enable Virtualisation Tooling";
              parent = cfg.virtualisation.enable;
            };

            docker.enable = mkEnabledNixosOption {
              description = "Whether or not to enable Docker";
              parent = cfg.virtualisation.enable;
            };

            libvirt.enable = mkEnabledNixosOption {
              description = "Whether or not to enable LibVirt";
              parent = cfg.virtualisation.enable;
            };

            podman.enable = mkEnabledNixosOption {
              description = "Whether or not to enable Podman";
              parent = cfg.virtualisation.enable;
            };

            waydroid.enable = mkEnabledNixosOption {
              description = "Whether or not to enable Waydroid (run android apps on Linux)";
              parent = cfg.virtualisation.enable;
            };
          };

          server = {
            enable = lib.mkEnableOption "Whether or not to install the server infrastructure";

            transmission.enable = mkEnabledNixosOption {
              description = "Whether or not to install the transmission bittorrent server";
              parent = cfg.server.enable;
            };

            gitea.enable = mkEnabledNixosOption {
              description = "Whether or not to install the Gitea Git Server";
              parent = cfg.server.enable;
            };
          };
        };
    };

    tmux.showBattery = lib.mkEnableOption "tmux show battery level";
  };
}
