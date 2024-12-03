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
        if [ -s /run/current-system/sw/bin/refind-install ]; then
          OLDPATH="$PATH"
          PATH="/run/current-system/sw/bin"
          # Install rEFInd
          ${pkgs.dusk.refind}/bin/refind-install
          
          # Copy theme files to EFI partition
          esp_mount=$(findmnt -n -o TARGET /boot/efi || findmnt -n -o TARGET /boot)
          themes_dir="$esp_mount/EFI/refind/themes"
          mkdir -p "$themes_dir"
          cp -r ${pkgs.dusk.refind}/share/refind/themes/* "$themes_dir/"
          
          # Configure refind.conf to use the theme
          refind_conf="$esp_mount/EFI/refind/refind.conf"
          if [ -f "$refind_conf" ]; then
            # Remove any existing include theme.conf lines
            sed -i '/^include themes\//d' "$refind_conf"
            # Add new theme include
            echo "include themes/catppuccin/theme.conf" >> "$refind_conf"
          fi
          
          PATH="$OLDPATH"
          printf 'true' > /tmp/refind
        else
          printf 'skip/true' > /tmp/refind
        fi
      '';
    };
  };
}
