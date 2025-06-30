let
  inherit (builtins)
    length
    filter
    head
    sort
    toString
    ;

  scaleToNumber = scale: if scale == "auto" then 1.0 else scale;
in
rec {
  cmpWith =
    func: a: b:
    func a > func b;
  resolutionToString = resolution: "${toString resolution.width}x${toString resolution.height}";

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

  formatMonitor = {
    hyprland =
      let
        rotationToNumber =
          rotate:
          {
            "0" = 0;
            "90" = 1;
            "180" = 2;
            "270" = 3;
          }
          .${toString rotate};

        vrrToNumber =
          vrr:
          if vrr == "fullscreen-only" then
            "2"
          else if vrr then
            "1"
          else if !vrr then
            "0"
          else
            throw "Invalid VRR value: ${toString vrr}";

      in
      {
        name,
        resolution ? {
          width = 1920;
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
        resolutionStr = resolutionToString resolution;
        positionStr = "${toString position.x}x${toString position.y}";
        transformNum =
          let
            rotateNum = rotationToNumber transform.rotate;
          in
          if transform.flipped then rotateNum + 4 else rotateNum;
      in
      "${name}, ${resolutionStr}@${toString refreshRate}, ${positionStr}, ${toString scale}, vrr, ${vrrToNumber vrr}, transform, ${toString transformNum}";

    sunshine = monitor: {
      inherit (monitor) name refreshRate;
      resolution = resolutionToString monitor.resolution;
    };
  };
}
