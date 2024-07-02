{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
in
{
  options.protoss.gnome.pipewire = {
    enable = mkOption {
      type = types.bool;
      default = config.protoss.gnome.enable;
      description = "Whether or not to enable PipeWire for sound.";
    };
  };

  config = mkIf config.protoss.gnome.pipewire.enable {
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
    };

    environment.systemPackages = with pkgs; [
      easyeffects
      helvum
    ];
  };
}
