{ lib, config, ... }:
let
  cfg = config.dusk.system.nixos.desktop.hyprland;

  # Default fallback monitor rule
  defaultFallbackRule = {
    name = ""; # Empty name makes it a fallback rule
    resolution.special = "preferred";
    position.special = "auto";
    scale = "auto";
    refreshRate = 60;
    mirror = null;
    bitDepth = null;
    vrr = null;
    transform = null;
  };

  # Merge user monitors with fallback rule
  monitorConfigs =
    cfg.monitors
    ++ lib.optional (!(lib.any (m: m.name == "") cfg.monitors)) defaultFallbackRule;

  # Format the monitor config string
  formatMonitor =
    monitor:
    let
      resolutionStr =
        if monitor.resolution.special != null then
          monitor.resolution.special
        else
          "${toString monitor.resolution.width}x${toString monitor.resolution.height}";

      positionStr =
        if monitor.position.special != null then
          monitor.position.special
        else
          "${toString monitor.position.x}x${toString monitor.position.y}";
    in
    "${monitor.name}, ${resolutionStr}@${toString monitor.refreshRate}, ${positionStr}, ${toString monitor.scale}";
in
{
  options.dusk.system.nixos.desktop.hyprland.monitors =
    with lib;
    mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Monitor name/identifier (can be empty for fallback rule)";
            };
            resolution = mkOption {
              type = types.submodule {
                options = {
                  width = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Monitor width in pixels";
                  };
                  height = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Monitor height in pixels";
                  };
                  special = mkOption {
                    type = types.nullOr (
                      types.enum [
                        "preferred"
                        "highres"
                        "highrr"
                      ]
                    );
                    default = null;
                    description = "Special resolution value (preferred, highres, highrr)";
                  };
                };
              };
              description = "Monitor resolution configuration";
            };
            position = mkOption {
              type = types.submodule {
                options = {
                  x = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Monitor X position";
                  };
                  y = mkOption {
                    type = types.nullOr types.int;
                    default = null;
                    description = "Monitor Y position";
                  };
                  special = mkOption {
                    type = types.nullOr (
                      types.enum [
                        "auto"
                        "auto-right"
                        "auto-left"
                        "auto-up"
                        "auto-down"
                      ]
                    );
                    default = null;
                    description = "Special position value";
                  };
                };
              };
              description = "Monitor position configuration";
            };

            refreshRate = mkOption {
              type = types.int;
              default = 60;
              description = "Monitor refresh rate in Hz";
            };

            scale = mkOption {
              type = types.either types.float (types.enum [ "auto" ]);
              default = 1.0;
              description = "Monitor scale factor (can be 'auto' or a float)";
            };

            mirror = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Name of the monitor to mirror";
            };

            bitDepth = mkOption {
              type = types.nullOr (
                types.enum [
                  8
                  10
                ]
              );
              default = null;
              description = "Color bit depth (8 or 10)";
            };
            vrr = mkOption {
              type = types.nullOr (
                types.enum [
                  0
                  1
                  2
                ]
              );
              default = null;
              description = "Variable refresh rate (0: off, 1: on, 2: fullscreen only)";
            };
            transform = mkOption {
              type = types.nullOr (
                types.enum [
                  0
                  1
                  2
                  3
                  4
                  5
                  6
                  7
                ]
              );
              default = null;
              description = "Transform/rotation (0: normal, 1: 90°, 2: 180°, 3: 270°, 4-7: flipped variants)";
            };
          };
        }
      );
      default = [ ];
      description = "Monitor configurations";
    };

  config = {
    home-manager.users.${config.dusk.username}.wayland.windowManager.hyprland.settings.monitor =
      map formatMonitor monitorConfigs;
  };
}
