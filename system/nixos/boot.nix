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
        systemd-boot.enable = lib.mkDefault true;
      };

      plymouth.enable = true;
    };

    environment.systemPackages = with pkgs; [
      dusk.refind
      efibootmgr
    ];

    hardware = {
      enableRedistributableFirmware = true;
      enableAllFirmware = true;

      cpu = {
        amd.updateMicrocode = true;
        intel.updateMicrocode = true;
      };
    };

    system.activationScripts.refind-install = {
      text = ''
        if [ -s /run/current-system/sw/bin/refind-install ];then
          OLDPATH="$PATH"
          PATH="/run/current-system/sw/bin"
          ${pkgs.dusk.refind}/bin/refind-install
          PATH="$OLDPATH"
          printf 'true' > /tmp/refind
        else
          printf 'skip/true' > /tmp/refind
        fi
      '';
    };
  };
}
