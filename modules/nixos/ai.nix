{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.dusk.ai;
in
{
  options.dusk.ai.enable = mkEnableOption "Enable AI tooling";

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      listenAddress = "0.0.0.0:11434";
      acceleration = mkIf config.dusk.nvidia.enable "cuda";
    };
  };
}
