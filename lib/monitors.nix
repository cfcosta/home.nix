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

    gnome = monitors: monitor: {
      inherit (monitor.position) x y;
      inherit (monitor.resolution) width height;

      connector = monitor.name;
      refresh-rate = monitor.refreshRate * 1000.0;
      scale = scaleToNumber monitor.scale;
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

    sunshine = monitor: {
      inherit (monitor) name refreshRate;
      resolution = resolutionToString monitor.resolution;
    };
  };
}
