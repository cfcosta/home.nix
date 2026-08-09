{ config, ... }: {
  config = {
    # Two keyboard groups — plain US and US-international — switched with
    # Alt+Shift, plus a Compose file adding the cedilla sequences. The compose
    # file is found through the environment rather than a config option, so the
    # same two variables are exported twice: into the compositor (below), which
    # covers native Wayland clients, and into the user's shell sessions
    # (further down), which covers anything launched from a terminal.
    dusk.system.nixos.desktop.hyprland.extraLuaConfig = ''
      hl.env("XCOMPOSEFILE",            "${config.dusk.folders.home}/.XCompose")
      hl.env("XKB_DEFAULT_COMPOSE_FILE", "${config.dusk.folders.home}/.XCompose")

      hl.config({
        input = {
          kb_layout  = "us,us",
          kb_variant = ",intl",
          kb_options = "grp:alt_shift_toggle",
        },
      })
    '';

    home-manager.users.${config.dusk.username} = {
      home.file.".XCompose".text = ''
        include "%L"

        <dead_acute> <c> : "ç" U00E7
        <dead_acute> <C> : "Ç" U00C7
      '';

      home.sessionVariables = {
        XCOMPOSEFILE = "${config.dusk.folders.home}/.XCompose";
        XKB_DEFAULT_COMPOSE_FILE = "${config.dusk.folders.home}/.XCompose";
      };
    };
  };
}
