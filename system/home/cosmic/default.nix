{
  config,
  flavor,
  inputs,
  lib,
  ...
}:
{
  config = lib.mkIf (flavor == "nixos" && config.dusk.system.nixos.desktop.enable) {
    xdg.configFile = {
      "cosmic/com.system76.CosmicComp/v1/autotile".text = "true";
      "cosmic/com.system76.CosmicComp/v1/autotile_behavior".text = "true";
      "cosmic/com.system76.CosmicComp/v1/focus_follows_cursor".text = "true";
      "cosmic/com.system76.CosmicComp/v1/cursor_follows_focus".text = "true";
      "cosmic/com.system76.CosmicTheme.Dark/v1/palette".source = "${inputs.catppuccin-cosmic}/cosmic-settings/Catppuccin-Mocha-Blue.ron";
      "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/palette".source = "${inputs.catppuccin-cosmic}/cosmic-settings/Catppuccin-Mocha-Blue.ron";
    };
  };
}
