{ lib, pkgs, config, dusk, ... }:
with lib; {
  config = {
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
      optionals (elem "gnome" dusk.modules) [ easyeffects helvum ];
  };
}
