{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.dusk.system.nixos.desktop.hyprland;
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };

      systemPackages = with pkgs; [
        grimblast
      ];
    };

    home-manager.users.${config.dusk.username} = {
      home.pointerCursor = {
        gtk.enable = true;
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 16;
      };

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

    services.xserver = {
      enable = true;

      displayManager.gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };
}
