{ mkUser }: {
  cfcosta = mkUser rec {
    name = "Cainã Costa";
    username = "cfcosta";
    email = "me@cfcosta.com";
    accounts.github = "cfcosta";

    platforms = [ "nixos" "darwin" ];
    root = ./cfcosta;

    modules = {
      darwin = {
        enable = [
          "alacritty"
          "android"
          "crypto"
          "default"
          "git"
          "mutt"
          "notes"
          "tmux"
        ];

        config.tmux.showBattery = true;
      };

      nixos = {
        enable = [
          "alacritty"
          "android"
          "crypto"
          "default"
          "git"
          "gnome"
          "media"
          "mutt"
          "notes"
          "tmux"
        ];

        config.gnome = {
          darkTheme = true;
          keymaps = [ "us" "us+intl" ];
        };
      };
    };

    config = {
      darwin = { config, lib, pkgs, ... }: {
        programs.bash.profileExtra = ''
          if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          fi
        '';
      };

      nixos = { config, lib, pkgs, ... }:
        {
          # Nothing
        };
    };
  };
}
