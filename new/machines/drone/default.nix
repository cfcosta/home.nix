{ config, pkgs, ... }:
{
  dusk-os = {
    enable = true;
    type = "darwin";

    modules = with config.dusk-os.modules; [
      ai.ollama
      messaging.element
      system.clipboard
      system.nix
    ];

    config = {
      users = pkgs.dusk-os.mkUser {
        name = "Cainã Costa";
        user = "cfcosta";
        email = "me@cfcosta.com";
        accounts.github = "cfcosta";
      };
    };
  };
}
