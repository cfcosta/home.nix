{
  config,
  pkgs,
  inputs,
  ...
}:
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
      pi-messenger
    ];

    home-manager.users.${config.dusk.username} = _: {
      home.file.".pi/agent/settings.json".text = builtins.toJSON {
        defaultProvider = "openai-codex";
        defaultModel = "gpt-5.3-codex";
        packages = [ "${inputs.pi-messenger}" ];
      };

      home.file.".pi/agent/pi-messenger.json".text = builtins.toJSON {
        crew = {
          concurrency = {
            workers = 3;
            max = 10;
          };

          coordination = "chatty";

          models = {
            planner = "openai-codex/gpt-5.3-codex";
            reviewer = "openai-codex/gpt-5.3-codex";
            worker = "openai-codex/gpt-5.3-codex";
          };

          planning.maxPasses = 3;
        };
      };
    };
  };
}
