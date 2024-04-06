{ config, ... }:
with config.dusk-os.lib.mkUser;
{
  dusk-os = {
    enable = true;
    type = "nixos";

    modules = with config.dusk-os.modules; [
      ai
      (messaging { only = with messaging; [ element ]; })
    ];

    config = {
      users = mkUser {
        name = "Cainã Costa";
        user = "cfcosta";
        email = "me@cfcosta.com";
        accounts.github = "cfcosta";
      };
    };
  };
}
