{ pkgs, ... }:
let
  theme.style = {
    name = "Catppuccin Mocha";
    body = {
      fgColor = "#cdd6f4";
      bgColor = "#1e1e2e";
      secondaryTextColor = "#cba6f7";
      tertiaryTextColor = "#cba6f7";
      borderColor = "#9399b2";
    };
    stat_table = {
      keyFgColor = "#cba6f7";
      valueFgColor = "#cdd6f4";
      logoColor = "#cba6f7";
    };
    proc_table = {
      fgColor = "#cdd6f4";
      fgWarning = "#fab387";
      fgPending = "#9399b2";
      fgCompleted = "#a6e3a1";
      fgError = "#f38ba8";
      headerFgColor = "#cba6f7";
    };
    help = {
      fgColor = "#cdd6f4";
      keyColor = "#cba6f7";
      hlColor = "#45475a";
      categoryFgColor = "#f5c2e7";
    };
    dialog = {
      fgColor = "#f5c2e7";
      bgColor = "#cba6f7";
      buttonFgColor = "#11111b";
      buttonBgColor = "#cba6f7";
      buttonFocusFgColor = "#11111b";
      buttonFocusBgColor = "#cba6f7";
      labelFgColor = "#f5e0dc";
      fieldFgColor = "#cdd6f4";
      fieldBgColor = "#585b70";
    };
  };

  toYAML =
    data:
    pkgs.runCommand "toYAML"
      {
        buildInputs = with pkgs; [ yj ];
        json = builtins.toJSON data;
        passAsFile = [ "json" ]; # will be available as `$jsonPath`
      }
      ''
        mkdir -p $out
        yj -jy < "$jsonPath" > $out/theme.yaml
      '';
in
{
  config.xdg.configFile."process-compose/theme.yaml".text = builtins.readFile "${toYAML theme}/theme.yaml";
}
