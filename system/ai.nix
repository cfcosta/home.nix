{ config, pkgs, ... }:
let
  inherit (pkgs.stdenv) isLinux;
  nvidiaEnabled = config.dusk.system.nixos.nvidia.enable;
in
{
  config = {
    environment.systemPackages = with pkgs; [
      crush
      opencode
      codex
      claude-code
      gemini-cli
    ];

    services.ollama = {
      enable = isLinux;
      package = if isLinux && nvidiaEnabled then pkgs.ollama-cuda else pkgs.ollama;
    };
  };
}
