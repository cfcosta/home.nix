{ config, inputs, ... }: {
  imports = with inputs.nixos-hardware.nixosModules; [
    common-cpu-amd
    common-pc-ssd
  ];

  config = {
    boot.initrd.kernelModules = [ "kvm-amd" ];

    dusk = {
      terminal.font-size = 12;

      shell.starship.disabledModules = [
        "cmd_duration"
        "dart"
        "fossil_branch"
        "fossil_metrics"
        "git_branch"
        "git_commit"
        "git_metrics"
        "git_state"
        "git_status"
        "gradle"
        "guix_shell"
        "hg_branch"
        "java"
        "package"
        "package"
        "pijul_channel"
        "vagrant"
      ];

      system = {
        hostname = "dusk";

        nixos = {
          nvidia.enable = false;

          desktop = {
            gaming.enable = true;
            hyprland.enable = true;

            # Emulators default to following gaming.enable, but they have no
            # place on an installer image: nothing here can supply the console
            # keys or firmware they need, and RPCS3 has no binary cache (see
            # system/hyprland/emulation.nix), so leaving them on would make
            # every ISO build compile it from source.
            emulation.enable = false;

            # Same reasoning for the streaming server: an installer image has
            # no Steam library to stream and no pairing state to keep, and
            # moonshine is built from source (no binary cache), so leaving it
            # on would only make every ISO build compile a Rust workspace.
            moonshine.enable = false;
          };
        };
      };
    };

    home-manager.users.${config.dusk.username} = {
      home.file.".XCompose".text = ''
        include "%L"

        <dead_acute> <c> : "ç" U00E7
        <dead_acute> <C> : "Ç" U00C7
      '';

      i18n.inputMethod.fcitx5.ignoreUserConfig = true;
    };

    dusk.system.nixos.desktop.hyprland.extraLuaConfig = ''
      hl.config({
        input = {
          kb_layout  = "us,us",
          kb_variant = ",intl",
          kb_options = "grp:alt_shift_toggle",
        },
      })
    '';

    i18n.inputMethod.fcitx5.settings.inputMethod = {
      GroupOrder."0" = "Default";
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "keyboard-us";
      };
      "Groups/0/Items/0".Name = "keyboard-us";
      "Groups/0/Items/1".Name = "keyboard-us-intl";
    };

    image.fileName = "dusk.iso";
    isoImage.volumeID = "DUSKOS";

    services.qemuGuest.enable = true;
  };
}
