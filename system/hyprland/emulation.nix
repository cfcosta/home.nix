{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.dusk.system.nixos.desktop.emulation;

  inherit (config.dusk.folders) home;

  # One core per system RomM actually holds ROMs for. Switch, PS3, GameCube and
  # Wii are absent on purpose: libretro has no core for the first two, and the
  # Dolphin core that would cover the other two writes GameCube saves into a
  # single memory card image shared by the whole library, which no save sync
  # can trace back to a game. Standalone eden, rpcs3 and dolphin below cover
  # all four.
  retroarch = pkgs.retroarch-bare.wrapper {
    cores = with pkgs.libretro; [
      beetle-psx-hw # psx
      citra # 3ds
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

      # Sorting by CORE as well is on by default, and would bury every save one
      # level deeper under the core's display name (saves/gba/mGBA/…). That
      # buys nothing here -- one core per system already -- and the extra level
      # would hide saves from the sync, so it is turned off explicitly rather
      # than left to a default that has already changed once.
      sort_savefiles_enable = "false";
      sort_savestates_enable = "false";

      # Never write saves next to the content. The content directory here IS
      # the RomM library, and stray .srm files in it would show up in RomM's
      # next scan as junk entries.
      savefiles_in_content_dir = "false";
      savestates_in_content_dir = "false";

      rgui_browser_directory = cfg.romsDirectory;
    };
  };

  # GameCube and Wii, from the standalone Dolphin instead of the libretro core
  # left out above.
  #
  # --config writes into Dolphin's command-line config layer, which is searched
  # ahead of the base layer Dolphin.ini is read from, and whose Save() is a
  # no-op. Same trick as RetroArch's --appendconfig above: these hold on every
  # launch, never land in Dolphin.ini, and leave the rest of the config
  # editable from the GUI. One argument each rather than "-C k=v", so a
  # romsDirectory with a space in it survives the wrapper's word splitting.
  #
  # SlotA=8 is EXIDeviceType::MemoryCardFolder, a directory holding one .gci
  # per save named after the game that wrote it. The alternative is a .raw
  # memory card image: one file carrying every game's saves at once, with no
  # way back from a save to the game it belongs to, which romm-save-sync can
  # therefore do nothing with. Dolphin has defaulted to the folder for years,
  # but nothing announces it if that ever flips -- saves keep working locally
  # and quietly stop reaching RomM -- so it is pinned rather than assumed.
  #
  # The ISO path is the ROM library, searched recursively so the per-platform
  # folders under it (ngc/, wii/) are what actually gets listed. Know the
  # trade: Config::GetIsoPaths reads the COUNT from the winning layer too, so
  # pinning it to one means a folder added from Config -> Paths is shadowed and
  # silently does nothing, and the pinned entry can't be removed there either.
  # That is the whole library in one root, so the cost is theoretical -- but if
  # a second root is ever wanted, it has to be added here, not in the GUI.
  dolphin = pkgs.symlinkJoin {
    name = "dolphin-emu-${pkgs.dolphin-emu.version}";
    paths = [ pkgs.dolphin-emu ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/dolphin-emu \
        --add-flag "--config=Dolphin.Core.SlotA=8" \
        --add-flag "--config=Dolphin.General.ISOPaths=1" \
        --add-flag "--config=Dolphin.General.ISOPath0=${cfg.romsDirectory}" \
        --add-flag "--config=Dolphin.General.RecursiveISOPaths=True"
    '';
    inherit (pkgs.dolphin-emu) meta;
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

      # GameCube and Wii, wrapped above with the ROM library and the save
      # layout already pointed at. What is still user-supplied -- same deal as
      # eden's keys and RPCS3's firmware -- is the dumps themselves being
      # unpacked: Dolphin reads .iso/.gcm/.ciso/.rvz/.wbfs and friends but has
      # no notion of a zip, which is how RomM stores most of this library, so a
      # zipped dump is invisible to the game list no matter where it points.
      dolphin
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
