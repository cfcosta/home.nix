{ config, pkgs, ... }:
{
  imports = [ ./playwright.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      beads
      claude-code
      codex
      crush
      gemini-cli
      opencode
      pi
    ];

    home-manager.users.${config.dusk.username} = _: {
      home.file.".pi/agent/settings.json".text = builtins.toJSON {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.3-codex";
        packages = [ pkgs.dusk-skills ];
      };

      home.file.".claude/skills" = {
        source = "${pkgs.dusk-skills.out}/skills";
        recursive = true;
      };

      home.file.".codex/skills" = {
        source = "${pkgs.dusk-skills.out}/skills";
        recursive = true;
      };
    };
  };
}
