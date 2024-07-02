{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (lib)
    types
    mkOption
    mkIf
    mkForce
    ;
  inherit (pkgs.stdenv) isLinux;
  inherit (pkgs.protoss.inputs) nixpkgs nix-darwin;

  cfg = config.protoss;
in
{
  options.protoss = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether or not to enable Protoss.";
    };

    profiles = builtins.listToAttrs (
      map (dir: {
        name = dir;
        value = mkOption {
          type = types.bool;
          default = true;
          description = "Whether or not to enable profile ${dir}";
        };
      }) (builtins.attrNames (builtins.readDir ./profiles))
    );

    user = {
      name = mkOption {
        type = types.str;
        description = "The full name of the user.";
      };

      username = mkOption {
        type = types.str;
        description = "The username for the user";
      };

      email = mkOption {
        type = types.str;
        description = "The email address of the user.";
      };

      accounts.github = mkOption {
        type = types.str;
        description = "The GitHub account of the user.";
      };

      folders = {
        code = mkOption {
          type = types.str;
          default = "${cfg.user.folders.home}/Code";
          description = "Where you host your working projects";
        };

        home = mkOption {
          type = types.str;
          default = if isLinux then "/home/${cfg.user.username}" else "/Users/${cfg.user.username}";
          description = "Your home folder";
        };
      };
    };
  };

  config = mkIf config.protoss.enable {
    # Make the whole system use the same <nixpkgs> as this flake.
    environment.etc."nix/inputs/nixpkgs".source = nixpkgs;
    environment.etc."nix/inputs/nix-darwin".source = nix-darwin;

    nix = {
      useDaemon = true;

      gc.automatic = true;

      settings = {
        accept-flake-config = true;
        auto-optimise-store = true;
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        system-features = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
      };

      # Configure nix to use the flake's nixpkgs
      registry.nixpkgs.flake = nixpkgs;
      registry.nix-darwin.flake = nix-darwin;
      nixPath = mkForce [ "/etc/nix/inputs" ];
    };
  };
}
