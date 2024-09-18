{ inputs, pkgs, ... }:
{
  config = {
    home.packages = [ pkgs.gitui ];

    xdg.configFile = {
      "gitui/theme.ron".source = "${inputs.catppuccin-gitui}/themes/catppuccin-mocha.ron";
      "gitui/key_bindings.ron".source = ./key_bindings.ron;
    };
  };

}
