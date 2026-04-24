{ config, pkgs, ... }:
let
  nvidiaEnabled = config.dusk.system.nixos.nvidia.enable;

  mcpServers.docbert = {
    command = toString "${if nvidiaEnabled then pkgs.docbert-cuda else pkgs.docbert}/bin/docbert";
    args = [ "mcp" ];
  };
in
{
  imports = [ ./playwright.nix ];

  config = {
    environment.systemPackages = with pkgs; [
      claude-code
      codex
      duskpi
    ];

    home-manager.users.${config.dusk.username} = _: {
      home.file = {
        ".pi/agent/settings.json".text = builtins.toJSON {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-5.5";
          defaultThinkingLevel = "high";
        };

        ".pi/agent/mcp.json".text = builtins.toJSON {
          inherit mcpServers;
        };

        ".mcp.json".text = builtins.toJSON {
          inherit mcpServers;
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
