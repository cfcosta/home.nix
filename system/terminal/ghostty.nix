{
  config,
  lib,
  flavor,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optionals
    types
    ;
  cfg = config.dusk.terminal;

  window-theme = if (flavor == "nixos") then "ghostty" else "system";
  crt-filter = ''
    float warp = 0.0; // simulate curvature of CRT monitor
    float scan = 0.50; // simulate darkness between scanlines

    void mainImage(out vec4 fragColor, in vec2 fragCoord)
    {
        // squared distance from center
        vec2 uv = fragCoord / iResolution.xy;
        vec2 dc = abs(0.5 - uv);
        dc *= dc;
        
        // warp the fragment coordinates
        uv.x -= 0.5; uv.x *= 1.0 + (dc.y * (0.3 * warp)); uv.x += 0.5;
        uv.y -= 0.5; uv.y *= 1.0 + (dc.x * (0.4 * warp)); uv.y += 0.5;

        // determine if we are drawing in a scanline
        float apply = abs(sin(fragCoord.y) * 0.25 * scan);
            
        // sample the texture
        vec3 color = texture(iChannel0, uv).rgb;

        // mix the sampled color with the scanline intensity
        fragColor = vec4(mix(color, vec3(0.0), apply), 1.0);
    }
  '';
in
{
  imports =
    optionals (flavor == "nixos") [ { environment.systemPackages = with pkgs; [ ghostty ]; } ]
    ++ optionals (flavor == "darwin") [
      {
        homebrew = {
          enable = true;
          casks = [ "ghostty" ];
        };
      }
    ];

  options.dusk.terminal.ghostty.theme = mkOption {
    description = "What theme to use on ghostty";
    type = types.str;
    default = "catppuccin-mocha";
  };

  config = mkIf (cfg.default == "ghostty") {
    home-manager.users.${config.dusk.username} = {
      programs.bash.initExtra = ''
        . ${pkgs.ghostty}/share/ghostty/shell-integration/bash/ghostty.bash
      '';

      xdg.configFile."ghostty/config".text = ''
        theme = ${cfg.ghostty.theme}
        font-family = ${cfg.font-family}
        font-size = ${toString cfg.font-size}
        background-opacity = 0.8
        background-blur-radius = 20
        window-decoration = false
        window-theme = ${window-theme}
        macos-titlebar-style = hidden
        custom-shader = ${pkgs.writeText "crt.glsl" crt-filter}
      '';
    };
  };
}
