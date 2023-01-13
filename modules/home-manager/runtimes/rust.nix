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
      cargo-audit
      cargo-watch
      cargo-nextest
      clang
      (rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "clippy" "rustfmt" "rust-analyzer" ];
      })
    ];
  };
}
