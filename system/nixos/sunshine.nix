{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (builtins)
    filter
    head
    length
    sort
    toString
    ;
  inherit (lib) mkIf optionals;

  scaleToNumber = scale: if scale == "auto" then 1.0 else scale;

  cmpWith =
    func: a: b:
    func a > func b;

  # Calculate effective pixels accounting for scaling
  getEffectivePixels =
    monitor: (monitor.resolution.width * monitor.resolution.height) / scaleToNumber monitor.scale;

  # Find monitor with highest effective pixel count if no primary is set
  defaultPrimaryMonitor =
    monitors:
    let
      sorted = sort (cmpWith getEffectivePixels) monitors;
    in
    if length sorted > 0 then (head sorted).name else null;

  getPrimaryMonitor =
    monitors:
    let
      explicit = filter (m: m.primary) monitors;
    in
    if length explicit > 0 then (head explicit).name else defaultPrimaryMonitor monitors;

  cfg = config.dusk.system.nixos.desktop.hyprland;

  generateImage =
    name: resolution:
    with pkgs;
    runCommand "cover.png" { buildInputs = [ imagemagick ]; } ''
      magick -size 600x800 \
        -background black \
        -fill white \
        -font ${nerd-fonts.inconsolata}/share/fonts/truetype/NerdFonts/Inconsolata/InconsolataNerdFont-Regular.ttf \
        -gravity center \
        -pointsize 64 \
        label:"${name}\n\n${resolution}" \
        $out
    '';

  prelude = ''
    set_hypr_instance_path() {
        local socket_dir
        local socket_path
        
        socket_dir="/run/user/$(id -u)/hypr"
        socket_path=$(find "$socket_dir" -type d -maxdepth 1 -name "*_*_*" 2>/dev/null | head -n1)
        
        if [ -n "$socket_path" ]; then
            HYPRLAND_INSTANCE_SIGNATURE=$(basename "$socket_path")
            export HYPRLAND_INSTANCE_SIGNATURE
            return 0
        else
            echo "Error: No Hyprland socket found in $socket_dir" >&2
            return 1
        fi
    }

    set_hypr_instance_path
  '';

  prepare =
    target:
    with pkgs;
    let
      primary = getPrimaryMonitor config.dusk.system.monitors;
    in
    writeShellApplication {
      name = "prepare";
      runtimeInputs = [
        hyprland
        findutils
      ];
      text = ''
        ${prelude}

        format_monitor() {
          local name=$1
          local width=$2
          local height=$3
          local refresh_rate=$4
          echo "$name,''${width}x''${height}@''${refresh_rate},auto,1"
        }

        echo "Setting monitor ${primary} to ${toString target.width}x${toString target.height}@${toString target.refreshRate}"
        hyprctl keyword monitor "$(format_monitor "${primary}" "${toString target.width}" "${toString target.height}" "${toString target.refreshRate}")"

        hyprctl dispatch focusmonitor "${primary}"
        hyprctl dispatch movecursor ${toString (target.width / 2)} ${toString (target.height / 2)}
      '';
    };

  teardown =
    with pkgs;
    writeShellApplication {
      name = "teardown";
      runtimeInputs = [ hyprland ];
      text = ''
        ${prelude}
        hyprctl reload
      '';
    };

  run =
    with pkgs;
    writeShellApplication {
      name = "run";
      runtimeInputs = [ hyprland ];
      text = ''
        ${prelude}

        # shellcheck disable=SC2068
        exec $@
      '';
    };

  targets = [
    {
      name = "1080p (60Hz)";
      width = 1920;
      height = 1080;
      refreshRate = 60.00;
    }
    {
      name = "1080p (120Hz)";
      width = 1920;
      height = 1080;
      refreshRate = 119.88;
    }
  ];

  mkApp =
    {
      prefix ? "Desktop",
      cmd ? "${pkgs.coreutils}/bin/true",
      target,
    }:
    {
      name = "${prefix} (${target.name})";
      image-path = "${generateImage prefix target.name}";
      cmd = "${run}/bin/run ${cmd}";
      prep-cmd = [
        {
          do = "${prepare target}/bin/prepare";
          undo = "${teardown}/bin/teardown";
        }
      ];
    };

  mkDesktop =
    target:
    mkApp {
      inherit target;
      prefix = "Desktop";
    };

  mkSteam =
    target:
    mkApp {
      inherit target;
      prefix = "Steam";
      cmd = "${pkgs.steam}/bin/steam steam://open/bigpicture";
    };

  primary = getPrimaryMonitor config.dusk.system.monitors;
  enable = cfg.enable && config.services.sunshine.enable && primary != null;
in
{
  config = mkIf enable {
    services.sunshine = {
      settings.output_name = primary;
      applications.apps =
        (map mkDesktop targets) ++ optionals config.programs.steam.enable (map mkSteam targets);
    };
  };
}
