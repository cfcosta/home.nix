{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (builtins) concatLists genList;

  cfg = config.dusk.system.nixos.desktop.hyprland;

  keybindings = {
    # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
    switch-workspace = concatLists (
      genList (
        i:
        let
          ws = i + 1;
        in
        [
          "$mod, code:1${toString i}, workspace, ${toString ws}"
          "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
        ]
      ) 9
    );
  };
in
{
  imports = [
    ./monitors.nix
  ];

  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };

      systemPackages = with pkgs; [
        dunst
        grimblast
      ];
    };

    home-manager.users.${config.dusk.username} = {
      imports = [
        ./dunst
        ./waybar
      ];

      gtk.enable = true;

      programs.hyprlock.enable = true;

      services = {
        hypridle.enable = true;
        hyprpaper.enable = true;
      };

      wayland.windowManager.hyprland = {
        enable = true;

        settings = {
          "$mod" = "SUPER";

          source = [ "${inputs.catppuccin-hyprland}/themes/mocha.conf" ];

          bind = [
            "$mod, Space, exec, ${pkgs.yofi}/bin/yofi apps"
            "$mod, Enter, exec, ${config.dusk.defaults.terminal}"
            "$mod, B, exec, ${config.dusk.defaults.browser}"
            ", Print, exec, grimblast copy area"
          ] ++ keybindings.switch-workspace;
        };

        systemd.variables = [ "--all" ];
      };
    };

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };

    security.pam.services.hyprlock = { };

    services.xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };
}
