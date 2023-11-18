{ inputs }:
let
  platforms = {
    darwin = {
      system = inputs.nix-darwin.darwinSystem;
      home = inputs.home-manager.darwinModules;
      nixpkgs = inputs.nix-darwin;
    };

    nixos = {
      system = inputs.nixpkgs.lib.nixosSystem;
      home = inputs.home-manager.nixosModules;
      nixpkgs = inputs.nixpkgs;
    };
  };

  platform = kind: platforms."${kind}";
in {
  mkSystem = { kind ? "nixos", system ? "x86_64-linux", users, extraConfig }:
    let
      pkgs = import platforms.${kind}.nixpkgs {
        inherit system;

        config.allowUnfree = true;
      };

      options = with pkgs.lib; {
        kind = mkOption {
          type = types.oneOf [ "nixos" "darwin" ];
          description = "the kind of system you're trying to build";
        };

        users = mkOption {
          type = types.listOf types.submodule {
            name = mkOption {
              type = types.str;
              description = "the username of the user";
            };

            initialPassword = mkOption {
              type = types.str;
              default = "dusk";
              description = "the initial password of the user";
            };
          };
          description = "the users in the system";
          default = [ ];
        };

        modules = {
          enable = mkOption {
            type = types.listOf types.str;
            default = [ ];
            check = key: builtins.pathExists ../platforms/${kind}/${key}.nix;
            description = "the modules to be enabled on the system";
          };

          config = mkOption {
            type = types.attrs;
            description = "extra config for the enabled modules";
          };
        };

        extraConfig = mkOption {
          type = types.submodule {
            config = mkOption {
              type = types.attr;
              description = "what is set when this module is enabled";
              default = { };
            };

            options = mkOption {
              type = types.attr;
              description = "the options this module accepts";
              default = { };
            };
          };
        };

        locale = mkOption {
          type = types.str;
          default = "en_US.utf8";
          description = "locale of the system";
        };
      };
    in platform.system {
      inherit pkgs;

      modules = [ extraConfig ];
    };

  mkUser =
    { name, username, email, accounts, platforms, root, config, extraConfig }:
    {

    };
}
