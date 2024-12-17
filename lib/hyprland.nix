rec {
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

  format-monitor =
    {
      name,
      resolution ? {
        witdh = 1920;
        height = 1080;
      },
      position ? {
        x = 0;
        y = 0;
      },
      scale ? 1.0,
      refreshRate ? 60.0,
      transform ? {
        rotate = 0;
        flipped = false;
      },
      vrr ? false,
      ...
    }:
    let
      resolutionStr = "${toString resolution.width}x${toString resolution.height}";
      positionStr = "${toString position.x}x${toString position.y}";
      vrrNum =
        if vrr == "fullscreen-only" then
          "2"
        else if vrr then
          "1"
        else if !vrr then
          "0"
        else
          throw "Invalid VRR value: ${toString vrr}";
      transformNum =
        let
          rotateNum =
            {
              "0" = 0;
              "90" = 1;
              "180" = 2;
              "270" = 3;
            }
            .${toString transform.rotate};
        in
        if transform.flipped then rotateNum + 4 else rotateNum;
    in
    "${name}, ${resolutionStr}@${toString refreshRate}, ${positionStr}, ${toString scale}, vrr, ${vrrNum}, transform, ${toString transformNum}";
}
