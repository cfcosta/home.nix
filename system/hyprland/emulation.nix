{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.dusk.system.nixos.desktop.emulation;

  inherit (config.dusk.folders) code home;

  # The RomM library as it exists on this disk: the homelab flake keeps it in
  # its working copy and 9p-shares it into the VM, so the host reads the very
  # same files RomM serves.
  romsDirectory = "${code}/cfcosta/homelab.nix/data/media/Roms/roms";

  # One core per system RomM actually holds ROMs for. Switch and PS3 are absent
  # on purpose -- libretro has no core for either, which is why eden and rpcs3
  # are separate packages below.
  retroarch = pkgs.retroarch-bare.wrapper {
    cores = with pkgs.libretro; [
      beetle-psx-hw # psx
      citra # 3ds
      dolphin # ngc
      gambatte # gb, gbc
      genesis-plus-gx # segacd
      melonds # nds
      mgba # gba
      snes9x # snes
    ];

    # Rendered to a config file the wrapper passes as --appendconfig, which
    # RetroArch layers over ~/.config/retroarch/retroarch.cfg at load and never
    # writes back to. So these hold on every launch while the rest of the
    # config stays writable from the GUI -- no fight over a file RetroArch
    # rewrites on exit.
    settings = {
      savefile_directory = "${home}/.config/retroarch/saves";
      savestate_directory = "${home}/.config/retroarch/states";
      system_directory = "${home}/.config/retroarch/system";

      # Saves land in a subfolder named after the directory the content came
      # from, which for this library is the RomM platform slug (roms/gba/… ->
      # saves/gba/…). That folder is the only thing tying a bare `.srm` back to
      # a platform, and romm-save-sync reads it to decide which RomM platform a
      # save belongs to. Multi-track disc rips live in a folder of their own,
      # so those sort under the game's name instead -- the sync handles both.
      sort_savefiles_by_content_enable = "true";
      sort_savestates_by_content_enable = "true";

      # Never write saves next to the content. The content directory here IS
      # the RomM library, and stray .srm files in it would show up in RomM's
      # next scan as junk entries.
      savefiles_in_content_dir = "false";
      savestates_in_content_dir = "false";

      rgui_browser_directory = romsDirectory;
    };
  };
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Multi-system emulation for everything in the RomM library that has a
      # libretro core. BIOS/keys that some cores need (PSX, Sega CD, 3DS) are
      # user-supplied under ~/.config/retroarch/system, same deal as eden's
      # keys below.
      retroarch

      # Switch emulator, from the Yuzu/Sudachi lineage. Qt6 with qtwayland and
      # a direct gamemode link, so it slots into the Hyprland session and picks
      # up the gamemode daemon gaming.nix runs. Decryption keys (prod.keys,
      # title.keys) are user-supplied under ~/.local/share/eden/keys — nothing
      # shippable from here.
      eden

      # PS3 emulator. nixpkgs tags it unfree *only* because it vendors wolfSSL,
      # which relicensed to GPL-3.0-or-later — arguably incompatible with
      # RPCS3's own GPL-2.0-only. The tag exists to keep Hydra from
      # redistributing that combination, not because the program is
      # proprietary. Two consequences: allowUnfree must be on (it is, set in
      # flake.nix), and there is no cache.nixos.org substitute, so this
      # compiles from source on every version bump. PS3 firmware (PS3UPDAT.PUP)
      # is user-supplied and installed through RPCS3's own UI.
      rpcs3
    ];

    # RPCS3 reproduces the PS3's memory layout with a very large number of
    # small mappings and fails to boot games once it exhausts them; the kernel
    # default (65530) is nowhere near enough. gaming.nix already raises this
    # for Steam/Proton, so keep it at mkDefault: it makes this module
    # self-sufficient when emulation runs without gaming, and yields to
    # gaming.nix's identical value otherwise instead of conflicting with it.
    boot.kernel.sysctl."vm.max_map_count" = mkDefault 1048576;

    # Valve's controller udev rules — the standard NixOS route to non-root HID
    # access for DualShock/DualSense and Switch Pro pads, which is how both
    # emulators expect to reach a gamepad. programs.steam turns this on
    # already in gaming.nix; declaring it here keeps controllers working if
    # emulation is ever enabled without Steam.
    hardware.steam-hardware.enable = true;
  };
}
