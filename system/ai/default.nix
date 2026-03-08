{ config, pkgs, ... }:
{
  imports = [ ./playwright.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      beads
      claude-code
      codex
      crush
      duskpi
      gemini-cli
      opencode
    ];

    home-manager.users.${config.dusk.username} = _: {
      home.file = {
        ".pi/agent/settings.json".text = builtins.toJSON {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-5.4";
        };

        ".claude/skills" = {
          source = "${pkgs.duskpi.out}/skills";
          recursive = true;
        };

        ".codex/skills" = {
          source = "${pkgs.duskpi.out}/skills";
          recursive = true;
        };
      };
    };
  };
}
