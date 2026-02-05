{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      beads
      claude-code
      codex
      crush
      gemini-cli
      opencode
    ];
  };
}
