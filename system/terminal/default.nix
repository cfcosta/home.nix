{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [
    ./alacritty.nix
    ./ghostty.nix
  ];

  options.dusk.terminal = {
    flavor = mkOption {
      description = "What terminal emulator to use";
      type = types.enum [
        "ghostty"
        "alacritty"
      ];
      default = "alacritty";
    };

    font-family = mkOption {
      type = types.str;
      default = "Inconsolata NerdFont";
    };

    font-size = mkOption {
      type = types.int;
      default = 14;
    };
  };
}
