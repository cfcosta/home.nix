{ config, pkgs, ... }:
{
  assertions = [
    {
      assertion = config.boot.loader.grub.efiSupport -> config.boot.systemd-boot.enable;
      message = "rEFInd is only compatible with EFI boot!";
    }
  ];

  environment.systemPackages = with pkgs; [
    refind
    efibootmgr
  ];

  system.activationScripts = {
    refind-install = {
      deps = [ ];
      text = ''
        if [ -s /run/current-system/sw/bin/refind-install ];then
          if [ ! -s /boot/EFI/refind/refind_x64.efi ]; then
            OLDPATH="$PATH"
            PATH="/run/current-system/sw/bin"
            ${pkgs.refind}/bin/refind-install
            PATH="$OLDPATH"
            printf 'true' > /tmp/refind
          else
            printf 'installed/true' > /tmp/refind
          fi
        else
          printf 'skip/true' > /tmp/refind
        fi
      '';
    };
  };
}
