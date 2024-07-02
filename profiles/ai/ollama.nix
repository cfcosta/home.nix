{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) mkOption types mkIf;
in
{
  options.protoss.ai.ollama = {
    enable = mkOption {
      type = types.bool;
      default = config.protoss.gnome.enable;
      description = "Whether or not to enable Ollama for local LLM access.";
    };
  };

  config = mkIf config.protoss.ai.ollama.enable {
    services.ollama = {
      enable = true;
      listenAddress = "0.0.0.0:11434";
      acceleration = mkIf config.protoss.hardware.nvidia.enable "cuda";
    };
  };
}
