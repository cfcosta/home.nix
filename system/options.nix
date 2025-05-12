{
  config,
  flavor,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  inherit (pkgs.stdenv) isLinux;

  mkEnabledOption =
    {
      description ? "Enable unnamed module",
      parent ? null,
    }:
    mkOption {
      inherit description;

      type = types.bool;
      default = parent == null || parent;
    };
in
{
  options.dusk = {
    initialPassword = mkOption {
      type = types.str;
      description = "Initial password for the created user in the system";
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
      description = "User name of the main user of the system";
    };

    defaults.browser = mkOption {
      type = types.str;
      description = "Your default browser";
      default = "${pkgs.brave}/bin/brave";
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
        description = "Locale of the system";
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

      zed = {
        enable = mkEnabledOption {
          description = "Whether or not to enable the Zed Editor";
          parent = true;
        };

        ui_font_family = mkOption {
          type = types.str;
          default = "Inconsolata NerdFont";
        };

        ui_font_size = mkOption {
          type = types.float;
          default = 16.0;
        };

        buffer_font_family = mkOption {
          type = types.str;
          default = "Inconsolata NerdFont";
        };

        buffer_font_size = mkOption {
          type = types.float;
          default = 16.0;
        };
      };

      nixos =
        let
          cfg = config.dusk.system.nixos;
        in
        {
          ai.enable = mkEnabledOption {
            description = "Whether or not to install AI Tools";
            parent = flavor == "nixos";
          };

          bootloader.enable = mkEnabledOption {
            description = "Whether or not to install a bootloader";
            parent = flavor == "nixos";
          };

          nvidia.enable = mkEnabledOption {
            description = "Whether or not to enable support for Nvidia Cards";
            parent = flavor == "nixos";
          };

          desktop = {
            enable = mkEnabledOption {
              description = "Whether or not to enable the Graphical Desktop";
              parent = flavor == "nixos";
            };

            gnome = {
              enable = mkEnabledOption {
                description = "Whether or not to enable the Gnome Desktop";
                parent = cfg.desktop.enable;
              };
            };

            hyprland = {
              enable = mkEnabledOption {
                description = "Whether or not to enable the Hyprland compositor";
                parent = cfg.desktop.enable && !cfg.desktop.gnome.enable;
              };
            };

            gaming = {
              enable = mkEnabledOption {
                description = "Whether or not to enable Gaming support (Steam, Gamemode, Gamescope)";
                parent = cfg.desktop.enable;
              };

              gamescope.enable = mkEnabledOption {
                description = "Whether or not to enable the Gamescope compositor";
                parent = cfg.desktop.gaming.enable;
              };
            };
          };

          networking = {
            enable = mkEnabledOption {
              description = "Whether or not to enable NetworkManager";
              parent = cfg.enable;
            };

            ip = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The static ip for this machine on the local network, if any";
            };

            tailscale.enable = mkEnabledOption {
              description = "Whether or not to enable Tailscale VPN";
              parent = cfg.networking.enable;
            };
          };

          virtualisation = {
            enable = mkEnabledOption { description = "Whether or not to enable Virtualisation Tooling"; };

            docker.enable = mkEnabledOption {
              description = "Whether or not to enable Docker";
              parent = cfg.virtualisation.enable;
            };

            libvirt.enable = mkEnabledOption {
              description = "Whether or not to enable LibVirt";
              parent = cfg.virtualisation.enable;
            };
          };

          server = {
            enable = lib.mkEnableOption "Whether or not to install the server infrastructure";

            domain = mkOption {
              type = types.str;
              default = "${config.dusk.system.hostname}.local";
              description = "The root domain for all services in the system";
            };
          };
        };
    };
  };
}
