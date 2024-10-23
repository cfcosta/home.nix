{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins) readFile;
  inherit (lib) mkIf;
  inherit (pkgs) writeText;

  cfg = config.dusk.system.nixos.desktop;
  accent = writeText "accent" (readFile ./accent.ron);
  shortcuts = writeText "custom" (readFile ./shortcuts.ron);
  palette = writeText "palette" (
    readFile "${inputs.catppuccin-cosmic}/cosmic-settings/Catppuccin-Mocha-Blue.ron"
  );
in
{
  config = mkIf cfg.enable {
    environment = {
      sessionVariables = {
        BROWSER = config.dusk.defaults.browser;
        TERMINAL = config.dusk.defaults.terminal;
        QT_QPA_PLATFORM = "wayland";
      };
    };

    home-manager.users.${config.dusk.username} = {
      dconf.settings."org/gnome/desktop/interface" = {
        font-name = "Cantarell 11";
        document-font-name = "Cantarell 11";
        monospace-font-name = "Cantarell 11";
      };

      home.activation.setupCosmicConfig = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p $HOME/.config/cosmic/com.system76.CosmicComp/v1
        mkdir -p $HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1
        mkdir -p $HOME/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}/v1
        mkdir -p $HOME/.config/cosmic/com.system76.CosmicTheme.{Dark,Light}.Builder/v1
        mkdir -p $HOME/.config/cosmic/com.system76.CosmicTk/v1

        cp ${shortcuts} $HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/

        cp ${accent} $HOME/.config/cosmic/com.system76.CosmicTheme.Dark/v1/
        cp ${palette} $HOME/.config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/
        cp ${palette} $HOME/.config/cosmic/com.system76.CosmicTheme.Dark/v1/
        echo "(8, 24)" > $HOME/.config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/gaps
        echo "(8, 24)" > $HOME/.config/cosmic/com.system76.CosmicTheme.Dark/v1/gaps

        cp ${accent} $HOME/.config/cosmic/com.system76.CosmicTheme.Light/v1/
        cp ${palette} $HOME/.config/cosmic/com.system76.CosmicTheme.Light.Builder/v1/
        cp ${palette} $HOME/.config/cosmic/com.system76.CosmicTheme.Light/v1/
        echo "(8, 24)" > $HOME/.config/cosmic/com.system76.CosmicTheme.Light.Builder/v1/gaps
        echo "(8, 24)" > $HOME/.config/cosmic/com.system76.CosmicTheme.Light/v1/gaps

        echo "true" > $HOME/.config/cosmic/com.system76.CosmicComp/v1/autotile
        echo "true" > $HOME/.config/cosmic/com.system76.CosmicComp/v1/autotile_behavior
        echo "true" > $HOME/.config/cosmic/com.system76.CosmicComp/v1/cursor_follows_focus
        echo "true" > $HOME/.config/cosmic/com.system76.CosmicComp/v1/focus_follows_cursor
        echo "true" > $HOME/.config/cosmic/com.system76.CosmicTk/v1/apply_theme_global

        cat ${writeText "bg_color.txt" ''
          Some((
              red: 0.11764706,
              green: 0.11764706,
              blue: 0.18039216,
              alpha: 1.0,
          ))
        ''} > $HOME/.config/cosmic/com.system76.CosmicTheme.Dark.Builder/v1/bg_color
      '';
    };

    services = {
      desktopManager.cosmic.enable = true;
      displayManager.cosmic-greeter.enable = true;
      flatpak.enable = true;
      libinput.enable = true;
      packagekit.enable = true;
    };

    specialisation = {
      cosmic.configuration = {
        environment.systemPackages = with pkgs; [
          adw-gtk3
          networkmanagerapplet
        ];
        system.nixos.tags = [ "Cosmic" ];
      };
    };
  };
}
