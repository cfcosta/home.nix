{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  config = mkIf config.dusk.system.nixos.bootloader.enable {
    boot = {
      loader = {
        efi.canTouchEfiVariables = true;

        systemd-boot = {
          enable = lib.mkDefault true;
          memtest86.enable = true;
        };
      };

      plymouth.enable = true;
    };

    environment.systemPackages = with pkgs; [ efibootmgr ];

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;

      cpu = {
        amd.updateMicrocode = true;
        intel.updateMicrocode = true;
      };
    };
  };
}
