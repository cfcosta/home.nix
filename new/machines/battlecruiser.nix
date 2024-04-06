{ config, pkgs, ... }:
{
  imports = [ ../default.nix ];

  dusk-os = {
    enable = true;
    type = "nixos";

    modules = with config.dusk-os.modules; [
      ai.ollama
      messaging.element
    ];

    config = {
      users = config.dusk-os.lib.mkUser {
        name = "Cainã Costa";
        user = "cfcosta";
        email = "me@cfcosta.com";
        accounts.github = "cfcosta";
      };
    };
  };
}
