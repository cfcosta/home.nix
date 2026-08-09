{
  config = {
    dusk.system.monitors = [
      {
        name = "DP-4";

        bitDepth = 10;
        position = {
          x = 0;
          y = 0;
        };
        refreshRate = 239.96;
        resolution = {
          width = 2560;
          height = 1440;
        };
        scale = 1.0;
        transform = {
          rotate = 90;
          flipped = false;
        };
        vrr = true;
      }
      {
        name = "HDMI-A-2";

        bitDepth = 10;
        position = {
          x = 1440;
          y = 2560 - 2160;
        };
        refreshRate = 119.88;
        resolution = {
          width = 3840;
          height = 2160;
        };
        scale = 1.0;
        transform = {
          rotate = 0;
          flipped = false;
        };
        vrr = true;
      }
    ];

    # Pin each workspace to a monitor: the first three to the landscape 4K
    # panel, the last three to the portrait one. Paired with the
    # `SUPER + CTRL + <n>` binds in desktop.nix, which focus a workspace on
    # whichever monitor the cursor is on.
    dusk.system.nixos.desktop.hyprland.extraLuaConfig = ''
      for _, ws in ipairs({ "1", "2", "3" }) do
        hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-2" })
      end
      for _, ws in ipairs({ "4", "5", "6" }) do
        hl.workspace_rule({ workspace = ws, monitor = "DP-4" })
      end
    '';
  };
}
