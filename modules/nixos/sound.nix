{ lib, pkgs, config, ... }:
with lib;
let cfg = config.devos;
in {
  imports = [ ./common.nix ];

  options.devos.sound = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether or not to enable sound in DevOS
      '';
    };
  };

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
      mkDefault config.devos.gnome.enable [ easyeffects helvum ];
  };
}
