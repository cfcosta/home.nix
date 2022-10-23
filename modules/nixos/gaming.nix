{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos.gaming;
in {
  imports = [ ./common.nix ];

  options = {
    devos.gaming.enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable the gnome desktop environment
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      bottles
      lutris
      mangohud
      retroarchFull
    ];

    hardware.opengl.enable = true;

    programs.steam.enable = true;
  };
}
