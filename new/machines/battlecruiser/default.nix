{
  type = "nixos";

  config =
    { config, pkgs, ... }:
    {
      imports = [ ./hardware.nix ];

      config = {
        dusk-os = {
          enable = true;

          modules = with config.dusk-os.modules; [
            ai.ollama
            messaging.element
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
      };
    };
}
