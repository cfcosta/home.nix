{ lib, config, ... }:
let
  inherit (lib) mkIf;
  cfg = config.dusk.system;

  # Calculate effective pixels accounting for scaling
  getEffectivePixels =
    monitor:
    let
      scale = if monitor.scale == "auto" then 1.0 else monitor.scale;
    in
    (monitor.resolution.width * monitor.resolution.height) / scale;

  # Find monitor with highest effective pixel count if no primary is set
  defaultPrimaryMonitor =
    monitors:
    let
      # Sort by effective pixels descending
      sorted = builtins.sort (a: b: getEffectivePixels a > getEffectivePixels b) monitors;
    in
    if builtins.length sorted > 0 then (builtins.head sorted).name else null;

  # Get primary monitor name, falling back to calculated default
  getPrimaryMonitor =
    monitors:
    let
      explicit = builtins.filter (m: m.primary) monitors;
    in
    if builtins.length explicit > 0 then
      (builtins.head explicit).name
    else
      defaultPrimaryMonitor monitors;

  # Format the monitor config string
  formatMonitor =
    monitor:
    let
      resolutionStr = "${toString monitor.resolution.width}x${toString monitor.resolution.height}";
      positionStr = "${toString monitor.position.x}x${toString monitor.position.y}";
      vrr =
        if monitor.vrr == "fullscreen-only" then
          "2"
        else if monitor.vrr then
          "1"
        else if !monitor.vrr then
          "0"
        else
          throw "Invalid VRR value: ${toString monitor.vrr}";
      transform =
        let
          rotateNum =
            {
              "0" = 0;
              "90" = 1;
              "180" = 2;
              "270" = 3;
            }
            .${toString monitor.transform.rotate};
        in
        if monitor.transform.flipped then rotateNum + 4 else rotateNum;
    in
    "${monitor.name}, ${resolutionStr}@${toString monitor.refreshRate}, ${positionStr}, ${toString monitor.scale}, vrr, ${vrr}, transform, ${toString transform}";

  # Format GNOME monitor config
  formatGnomeMonitor = monitors: monitor: {
    inherit (monitor.position) x y;
    inherit (monitor.resolution) width height;

    connector = monitor.name;
    refresh-rate = monitor.refreshRate * 1000.0; # GNOME uses mHz
    scale = if monitor.scale == "auto" then 0 else monitor.scale;
    is-primary = monitor.name == getPrimaryMonitor monitors;
    rotation =
      if monitor.transform.rotate == 0 then
        1
      else if monitor.transform.rotate == 90 then
        2
      else if monitor.transform.rotate == 180 then
        4
      else if monitor.transform.rotate == 270 then
        8
      else
        throw "Invalid rotation value";
  };
in
{
  options.dusk.system.monitors =
    with lib;
    mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "Monitor name/identifier";
            };
            primary = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this is the primary display";
            };
            resolution = mkOption {
              type = types.submodule {
                options = {
                  width = mkOption {
                    type = types.int;
                    description = "Monitor width in pixels";
                  };
                  height = mkOption {
                    type = types.int;
                    description = "Monitor height in pixels";
                  };
                };
              };
              description = "Monitor resolution configuration";
            };
            position = mkOption {
              type = types.submodule {
                options = {
                  x = mkOption {
                    type = types.int;
                    description = "Monitor X position";
                  };
                  y = mkOption {
                    type = types.int;
                    description = "Monitor Y position";
                  };
                };
              };
              description = "Monitor position configuration";
            };
            refreshRate = mkOption {
              type = types.either types.int types.float;
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
              type = types.oneOf [
                types.bool
                (types.enum [ "fullscreen-only" ])
              ];
              default = false;
              description = ''
                Variable refresh rate (false: off, true: on, "fullscreen-only": only when running a full-screen application)";
              '';
            };
            transform = mkOption {
              type = types.submodule {
                options = {
                  rotate = mkOption {
                    type = types.enum [
                      0
                      90
                      180
                      270
                    ];
                    default = 0;
                    description = "Rotation in degrees (0, 90, 180, or 270)";
                  };
                  flipped = mkOption {
                    type = types.bool;
                    default = false;
                    description = "Whether the output is flipped";
                  };
                };
              };
              default = {
                rotate = 0;
                flipped = false;
              };
              description = "Transform configuration for rotation and flipping";
            };
          };
        }
      );
      default = [ ];
      description = "Monitor configurations";
    };

  config = {
    environment.etc."gnome-settings-daemon/monitors.xml" = mkIf cfg.nixos.desktop.gnome.enable {
      text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <monitors version="2">
          ${lib.concatMapStrings (monitor: ''
            <configuration>
              <logicalmonitor>
                <x>${toString monitor.position.x}</x>
                <y>${toString monitor.position.y}</y>
                <scale>${if monitor.scale == "auto" then "1" else toString monitor.scale}</scale>
                <primary>${if monitor.name == getPrimaryMonitor cfg.monitors then "yes" else "no"}</primary>
                <monitor>
                  <monitorspec>
                    <connector>${monitor.name}</connector>
                    <vendor>unknown</vendor>
                    <product>unknown</product>
                    <serial>unknown</serial>
                  </monitorspec>
                  <mode>
                    <width>${toString monitor.resolution.width}</width>
                    <height>${toString monitor.resolution.height}</height>
                    <rate>${toString (monitor.refreshRate * 1000.0)}</rate>
                  </mode>
                  <transform>
                    <rotation>${
                      if monitor.transform.rotate == 0 then
                        "normal"
                      else if monitor.transform.rotate == 90 then
                        "right"
                      else if monitor.transform.rotate == 180 then
                        "upside_down"
                      else if monitor.transform.rotate == 270 then
                        "left"
                      else
                        throw "Invalid rotation value"
                    }</rotation>
                    <flipped>${if monitor.transform.flipped then "yes" else "no"}</flipped>
                  </transform>
                </monitor>
              </logicalmonitor>
            </configuration>
          '') cfg.monitors}
        </monitors>
      '';
    };

    home-manager.users.${config.dusk.username} = {
      dconf.settings = mkIf cfg.nixos.desktop.gnome.enable {
        "org/gnome/mutter" = {
          experimental-features = [ "scale-monitor-framebuffer" ];
        };

        "org/gnome/desktop/interface" = {
          scaling-factor = 1;
        };

        "org/gnome/mutter/displays" = {
          monitors-config-format = "json";
          monitors-config = builtins.toJSON {
            version = 2;
            monitors = map (formatGnomeMonitor cfg.monitors) cfg.monitors;
          };
        };
      };

      wayland.windowManager.hyprland = mkIf cfg.nixos.desktop.hyprland.enable {
        settings.monitor = map formatMonitor cfg.monitors;
      };
    };
  };
}
