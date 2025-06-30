{ config, ... }:
let
  inherit (config.dusk) username;
in
{
  config = {
    services = {
      flatpak = {
        enable = true;

        packages = [
          "org.expresslrs.ExpressLRSConfigurator"
          "io.github.betaflight.BetaflightConfigurator"
        ];

        remotes = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
      };

      udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="2e3c", ATTRS{idProduct}=="df11", MODE="0664", GROUP="plugdev"
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="314b", ATTRS{idProduct}=="0106", MODE="0664", GROUP="plugdev"
      '';
    };

    systemd.services.ModemManager.enable = false;
    users.users.${username}.extraGroups = [
      "plugdev"
      "dialout"
    ];
  };
}
