{ lib, pkgs, config, ... }:
with lib;
let cfg = config.dusk.sound;
in {
  options.dusk.sound.enable = mkEnableOption "sound";

  config = mkIf cfg.enable {
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs;
      optionals config.dusk.gnome.enable [ easyeffects helvum ];
  };
}
