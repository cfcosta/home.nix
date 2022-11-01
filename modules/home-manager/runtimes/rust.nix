{ config, lib, pkgs, ... }:
with lib;
let cfg = config.devos.home.runtimes.rust;
in {
  options = {
    devos.home.runtimes.rust = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      cargo-watch
      crate2nix
      clang
      mold
      clang
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "clippy" "rustfmt" "rust-analyzer" ];
      })
    ];

    home.sessionVariables.RUSTFLAGS = "-C link-arg=-fuse-ld=mold";
  };
}
