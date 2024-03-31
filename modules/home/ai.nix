{ pkgs, lib, config, ... }:
with lib;
let cfg = config.dusk.home;
in {
  options.dusk.home = { ai.enable = mkEnableOption "AI tools"; };
  config = mkIf cfg.notes.enable {
    home.packages = with pkgs; [ (ollama.override { acceleration = "cuda"; }) ];
  };
}
