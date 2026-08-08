{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;

  cfg = config.dusk.system.nixos.desktop.emulation;
in
{
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
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
