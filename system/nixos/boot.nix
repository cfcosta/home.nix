{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.dusk.system.nixos.bootloader.enable {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = lib.mkDefault true;
    };

    environment.systemPackages = with pkgs; [
      dusk.catppuccin-refind
      efibootmgr
    ];

    hardware = {
      enableRedistributableFirmware = true;
      cpu.amd.updateMicrocode = true;
    };

    system.activationScripts = {
      refind-install = {
        deps = [ ];
        text = ''
          if [ -s /run/current-system/sw/bin/refind-install ];then
            OLDPATH="$PATH"
            PATH="/run/current-system/sw/bin"
            ${pkgs.dusk.catppuccin-refind}/bin/refind-install
            PATH="$OLDPATH"
            printf 'true' > /tmp/refind
          else
            printf 'skip/true' > /tmp/refind
          fi
        '';
      };
    };
  };
}
