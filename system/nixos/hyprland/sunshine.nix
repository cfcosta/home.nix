{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.strings) sanitizeDerivationName;
  inherit (import ../../../lib) hyprland;

  cfg = config.dusk.system.nixos.desktop.hyprland;

  output_name = "SUNSHINE";

  generateImage =
    name: resolution:
    with pkgs;
    runCommand "sunshine-${sanitizeDerivationName name}.png"
      {
        buildInputs = [
          imagemagick
          nerd-fonts.inconsolata
        ];
      }
      ''
        magick -size 600x800 \
          -background black \
          -fill white \
          -font ${nerd-fonts.inconsolata}/share/fonts/truetype/NerdFonts/Inconsolata/InconsolataNerdFont-Regular.ttf \
          -gravity center \
          -pointsize 48 \
          label:"${name}\n${resolution}" \
          $out
      '';

  headless =
    {
      width,
      height,
      refreshRate,
      ...
    }:
    hyprland.format-monitor {
      inherit refreshRate;

      name = output_name;
      bitDepth = 8;
      position = {
        x = 0;
        y = 0;
      };
      resolution = { inherit width height; };
      scale = 1.0;
      vrr = true;
    };

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

  run =
    target:
    with pkgs;
    writeShellApplication {
      name = "hyprland-sunshine-run";
      text = ''
        ${prelude}

        teardown() {
          hyprctl output remove ${output_name}
        }
        trap teardown EXIT

        if hyprctl monitors all | grep -q "${output_name}"; then
          hyprctl output remove "${output_name}" || true
        fi

        hyprctl output create headless ${output_name}
        hyprctl keyword monitor '${headless target}'

        # Ensure Steam Big Picture windows move to SUNSHINE monitor
        hyprctl keyword windowrule "move,steam,${output_name}"

        # Move the mouse cursor to the center of the SUNSHINE monitor
        hyprctl dispatch focusmonitor ${output_name}
        hyprctl dispatch movecursor ${toString (target.width / 2)} ${toString (target.height / 2)}

        # shellcheck disable=2068
        hyprctl execr $@

        teardown
      '';
    };

  targets = [
    {
      name = "1080p@60";
      width = 1920;
      height = 1080;
      refreshRate = 60.00;
    }
    {
      name = "1080p@120";
      width = 1920;
      height = 1080;
      refreshRate = 120.00;
    }
    {
      name = "4k@60";
      width = 3840;
      height = 2160;
      refreshRate = 60.00;
    }
    {
      name = "4k@120";
      width = 3840;
      height = 2160;
      refreshRate = 120.00;
    }
    {
      name = "Macbook@60\n\n(No Notch)";
      width = 3024;
      height = 1890;
      refreshRate = 60.00;
      scale = 2.0;
    }
    {
      name = "Macbook@120\n\n(No Notch)";
      width = 3024;
      height = 1890;
      refreshRate = 120.00;
      scale = 2.0;
    }
    {
      name = "Macbook@60\n\n(Notch)";
      width = 3024;
      height = 1964;
      refreshRate = 60.00;
      scale = 2.0;
    }
    {
      name = "Macbook@120\n\n(Notch)";
      width = 3024;
      height = 1964;
      refreshRate = 120.00;
      scale = 2.0;
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
      cmd = "${run target}/bin/hyprland-sunshine-run ${cmd}";
      exclude-global-prep-cmd = "false";
      auto-detach = if cmd == "${pkgs.coreutils}/bin/true" then "true" else "false";
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
      cmd = "${pkgs.gamemode}/bin/gamemoderun ${pkgs.steam}/bin/steam steam://open/bigpicture";
    };
in
{
  config = mkIf (cfg.enable && config.services.sunshine.enable) {
    services.sunshine = {
      settings = { inherit output_name; };

      applications.apps = (map mkDesktop targets) ++ (map mkSteam targets);
    };
  };
}
