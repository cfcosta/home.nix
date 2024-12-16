{
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
