{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;
  cfg = config.dusk.sound;
in
{
  options.dusk.sound.enable = mkEnableOption "sound";

  config = mkIf cfg.enable {
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = optionals config.dusk.gnome.enable (
      with pkgs;
      [
        easyeffects
        helvum
      ]
    );
  };
}
